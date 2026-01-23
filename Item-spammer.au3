#cs =============================================================================================================================
	Item-Spammer version 1.1.0
	Author: Arca
	Status: Public
    Purpose: It helps ease the pain of spamming items for the Drunkard, Party Animal and Sweet Tooth titles.

    Features:
	    - Automatic use of items in player's inventory for 3 categories: Alcohol, Sweet and Party.
	    - Multi-category selection: spam 1, 2, or all 3 categories in a single session.
	    - Real-time title tracking.
	    - The bot automatically stops when 10,000 points are reached.
	    - Uses the least valuable items first (1 pt → 2 pts → 3 pts, etc.) to preserve higher-value items.
#ce =============================================================================================================================

#RequireAdmin

#Region Includes
; #INCLUDES# ====================================================================================================================
#include "..\..\API\_GwAu3.au3"
#include "Files\AddOns.au3"
#include "Files\GUI.au3"
; ===============================================================================================================================
#EndRegion Includes

Opt("GUIOnEventMode", True)
Opt("GUICloseOnESC", False)

#Region Global Variables
; Bot state
Global $BotRunning = False
Global $BotInitialized = False

; Category selection and processing
Global $SelectedCategories[3] = [False, False, False] ; [0]=Alcohol, [1]=Party, [2]=Sweet
Global $CurrentCategoryIndex = -1 ; Current category being processed (-1 = none)
Global $CategoryQueue[0] ; Queue of category indices to process

; Title tracking (all 3 titles)
; [0]=Drunkard, [1]=Party Animal, [2]=Sweet Tooth
Global $g_iTitleStartPoints[3] = [0, 0, 0] ; Starting points when bot started
Global $g_iTitleCurrentPoints[3] = [0, 0, 0] ; Current points from API
Global $g_iTitlePointsGained[3] = [0, 0, 0] ; Points gained this session

Global $ItemsUsed = 0
Global $StartTime = 0 ; Current run start time
Global $AccumulatedRuntime = 0 ; Total accumulated runtime (milliseconds)
Global $FinalRuntime = "" ; Stores final runtime when bot stops

; Character info
Global $CurrentCharacter = ""
#EndRegion Global Variables

#Region Title Sync Functions
Func SyncTitlePointsFromGame()
	; Sync all 3 title points from game memory using Title_GetTitleInfo
	; Title IDs: Drunkard=$GC_E_TITLEID_DRUNKARD, Party=$GC_E_TITLEID_PARTY, Sweet=$GC_E_TITLEID_SWEETS
	; Returns: True on success, False on error
	
	Local Static $aTitleIDs[3] = [$GC_E_TITLEID_DRUNKARD, $GC_E_TITLEID_PARTY, $GC_E_TITLEID_SWEETS]
	Local Static $aTitleNames[3] = ["Drunkard", "Party Animal", "Sweet Tooth"]
	
	Local $bSuccess = True
	
	; Loop through all 3 titles
	For $i = 0 To 2
		Local $pts = Title_GetTitleInfo($aTitleIDs[$i], "CurrentPoints")
		If $pts >= 0 Then
			$g_iTitleCurrentPoints[$i] = $pts
		Else
			LogMessage("Warning: Failed to read " & $aTitleNames[$i] & " title points")
			$bSuccess = False
		EndIf
	Next
	
	; Calculate points gained (current - start)
	For $i = 0 To 2
		$g_iTitlePointsGained[$i] = $g_iTitleCurrentPoints[$i] - $g_iTitleStartPoints[$i]
	Next
	
	Return $bSuccess
EndFunc

Func InitializeTitleTracking()
	; Called when bot starts - captures starting points for all 3 titles
	; Returns: True on success, False on error
	
	If Not SyncTitlePointsFromGame() Then
		LogMessage("Error: Failed to initialize title tracking")
		Return False
	EndIf
	
	; Store as starting points
	For $i = 0 To 2
		$g_iTitleStartPoints[$i] = $g_iTitleCurrentPoints[$i]
		$g_iTitlePointsGained[$i] = 0
	Next
	
	LogMessage("Title tracking initialized:")
	LogMessage("  - Drunkard: " & $g_iTitleStartPoints[0] & " points")
	LogMessage("  - Party Animal: " & $g_iTitleStartPoints[1] & " points")
	LogMessage("  - Sweet Tooth: " & $g_iTitleStartPoints[2] & " points")
	
	Return True
EndFunc
#EndRegion Title Sync Functions

#Region Bot Functions
Func BuildCategoryQueue()
	; Build queue of categories to process based on selection
	; Returns True if at least one category is selected, False otherwise
	ReDim $CategoryQueue[0]
	
	For $i = 0 To 2
		If $SelectedCategories[$i] Then
			Local $iSize = UBound($CategoryQueue)
			ReDim $CategoryQueue[$iSize + 1]
			$CategoryQueue[$iSize] = $i
		EndIf
	Next
	
	Return (UBound($CategoryQueue) > 0)
EndFunc

Func GetCategoryName($iCategory)
	; Returns category name as string
	Switch $iCategory
		Case $CATEGORY_ALCOHOL
			Return "Alcohol"
		Case $CATEGORY_PARTY
			Return "Party"
		Case $CATEGORY_SWEET
			Return "Sweet"
		Case Else
			Return "Unknown"
	EndSwitch
EndFunc

Func StartNextCategory()
	; Start processing the next category in the queue
	; Returns True if a category was started, False if queue is empty
	
	If UBound($CategoryQueue) = 0 Then
		; No more categories to process
		$CurrentCategoryIndex = -1
		Return False
	EndIf
	
	; Get next category from queue
	$CurrentCategoryIndex = $CategoryQueue[0]
	
	; Remove from queue (shift array)
	Local $iQueueSize = UBound($CategoryQueue)
	If $iQueueSize > 1 Then
		Local $aTempQueue[$iQueueSize - 1]
		For $i = 1 To $iQueueSize - 1
			$aTempQueue[$i - 1] = $CategoryQueue[$i]
		Next
		$CategoryQueue = $aTempQueue
	Else
		ReDim $CategoryQueue[0]
	EndIf
	
	; Log category start
	LogMessage("Processing category: " & GetCategoryName($CurrentCategoryIndex))
	
	Return True
EndFunc

Func StartBot()
	If $CurrentCharacter = "" Then
		LogMessage("Error: Please select a character")
		Return
	EndIf
	
	; Build category queue from selections
	If Not BuildCategoryQueue() Then
		LogMessage("Error: Please select at least one category")
		Return
	EndIf
	
	LogMessage("Initializing...")
	
	; Initialize GwAu3
	Local $initResult = Core_Initialize($CurrentCharacter, True)
	If $initResult = 0 Then
		LogMessage("Error: Could not find character '" & $CurrentCharacter & "'")
		LogMessage("Please ensure Guild Wars is running and you are logged in")
		Return
	EndIf
	
	$CurrentCharacter = Player_GetCharname()
	
	; Verify character name was retrieved successfully
	If StringLen($CurrentCharacter) = 0 Then
		LogMessage("Error: Failed to retrieve character name from game")
		Return
	EndIf
	
	; Verify we're in an outpost or guild hall
	Local $instanceType = Map_GetInstanceInfo("Type")
	If $instanceType <> 0 And $instanceType <> 1 Then
		LogMessage("Error: You must be in an Outpost or Guild Hall to use items")
		LogMessage("Current location type: " & $instanceType & " (0=Outpost, 1=Guild Hall, 2=Explorable)")
		Return
	EndIf
	
	GUICtrlSetData($cbx_char_select, $CurrentCharacter, $CurrentCharacter)
	GUICtrlSetState($cbx_char_select, $GUI_DISABLE)
	
	; Initialize title tracking (fetch starting points from API)
	If Not InitializeTitleTracking() Then
		LogMessage("Error: Bot initialization failed - cannot read title data")
		LogMessage("Please ensure you are logged into the game")
		Return
	EndIf
	
	; Reset counters
	$ItemsUsed = 0
	$StartTime = TimerInit()
	$AccumulatedRuntime = 0 ; Reset accumulated runtime
	$FinalRuntime = "" ; Reset final runtime
	UpdateStatusDisplay()
	
	$BotInitialized = True
	$BotRunning = True
	UpdateStartButtonState()
	
	; Log selected categories
	Local $sCategories = ""
	For $i = 0 To 2
		If $SelectedCategories[$i] Then
			If $sCategories <> "" Then $sCategories &= ", "
			$sCategories &= GetCategoryName($i)
		EndIf
	Next
	
	LogMessage("Script started - Categories: " & $sCategories)
	
	; Start first category
	StartNextCategory()
EndFunc

Func StopBot()
	$BotRunning = False
	
	; Add current run time to accumulated runtime
	$AccumulatedRuntime += TimerDiff($StartTime)
	
	; Calculate total session duration and freeze it
	$FinalRuntime = FormatMillisecondsAsTime($AccumulatedRuntime)
	
	; Final title sync to ensure accurate session summary
	If $BotInitialized Then
		SyncTitlePointsFromGame()
		UpdateStatusDisplay() ; Refresh GUI with final frozen values
	EndIf
	
	LogMessage("Script stopped" & @CRLF & "--------")
	LogMessage("Session summary:")
	LogMessage("  - Runtime: " & $FinalRuntime)
	LogMessage("  - Items used: " & $ItemsUsed)
	LogMessage("  - Drunkard: +" & $g_iTitlePointsGained[0] & " points (Total: " & $g_iTitleCurrentPoints[0] & ")")
	LogMessage("  - Party Animal: +" & $g_iTitlePointsGained[1] & " points (Total: " & $g_iTitleCurrentPoints[1] & ")")
	LogMessage("  - Sweet Tooth: +" & $g_iTitlePointsGained[2] & " points (Total: " & $g_iTitleCurrentPoints[2] & ")")
	UpdateStartButtonState()
EndFunc

#EndRegion Bot Functions

#Region Item Functions
Func GetCategoryItemsInInventory($iCategory)
	; Returns array of item pointers for selected category from inventory bags (1-4)
	; Uses existing GwAu3 arrays - combines at runtime
	; Returns 2D array: [ItemPtr, ModelID, Points]
	
	; Validate category parameter
	If $iCategory < 0 Or $iCategory > 2 Then
		LogMessage("Error: Invalid category " & $iCategory)
		Local $aEmpty[0][3]
		Return $aEmpty
	EndIf
	
	Local $aItems[0][3] ; [ItemPtr, ModelID, Points]
	Local $aItemModelIDs[0]
	Local $iModelIdx = 0
	
	; Get ModelIDs for selected category - Pre-allocate array for performance
	Switch $iCategory
		Case $CATEGORY_ALCOHOL
			; Pre-allocate array size
			Local $iTotalSize = $GC_AI_ONEPOINT_ALCOHOL[0] + $GC_AI_THREEPOINT_ALCOHOL[0] + $GC_AI_FIFTYPOINT_ALCOHOL[0]
			ReDim $aItemModelIDs[$iTotalSize]
			
			; Fill array directly without resizing
			For $i = 1 To $GC_AI_ONEPOINT_ALCOHOL[0]
				$aItemModelIDs[$iModelIdx] = $GC_AI_ONEPOINT_ALCOHOL[$i]
				$iModelIdx += 1
			Next
			For $i = 1 To $GC_AI_THREEPOINT_ALCOHOL[0]
				$aItemModelIDs[$iModelIdx] = $GC_AI_THREEPOINT_ALCOHOL[$i]
				$iModelIdx += 1
			Next
			For $i = 1 To $GC_AI_FIFTYPOINT_ALCOHOL[0]
				$aItemModelIDs[$iModelIdx] = $GC_AI_FIFTYPOINT_ALCOHOL[$i]
				$iModelIdx += 1
			Next
			
		Case $CATEGORY_PARTY
			; Pre-allocate array size
			Local $iTotalSize = UBound($GC_AI_SPAMMABLE_PARTY) - 1 + UBound($GC_AI_NON_SPAMMABLE_PARTY) - 1 + $GC_AI_PARTY_TONICS_2PT[0] + 4
			ReDim $aItemModelIDs[$iTotalSize]
			
			; Fill array directly without resizing
			For $i = 1 To UBound($GC_AI_SPAMMABLE_PARTY) - 1
				$aItemModelIDs[$iModelIdx] = $GC_AI_SPAMMABLE_PARTY[$i]
				$iModelIdx += 1
			Next
			For $i = 1 To UBound($GC_AI_NON_SPAMMABLE_PARTY) - 1
				$aItemModelIDs[$iModelIdx] = $GC_AI_NON_SPAMMABLE_PARTY[$i]
				$iModelIdx += 1
			Next
			; Add 2-point party tonics
			For $i = 1 To $GC_AI_PARTY_TONICS_2PT[0]
				$aItemModelIDs[$iModelIdx] = $GC_AI_PARTY_TONICS_2PT[$i]
				$iModelIdx += 1
			Next
			; Add other party tonics (3, 5, 25 points)
			$aItemModelIDs[$iModelIdx] = $GC_I_MODELID_MINUTELY_MAD_KING_TONIC  ; 3pt
			$iModelIdx += 1
			$aItemModelIDs[$iModelIdx] = $GC_I_MODELID_ZAISHEN_TONIC            ; 3pt
			$iModelIdx += 1
			$aItemModelIDs[$iModelIdx] = $GC_I_MODELID_MYSTERIOUS_TONIC         ; 5pt
			$iModelIdx += 1
			$aItemModelIDs[$iModelIdx] = $GC_I_MODELID_SPOOKY_TONIC             ; 25pt
			$iModelIdx += 1
			
		Case $CATEGORY_SWEET
			; Pre-allocate array size (10 items)
			; Only includes items usable in outposts/guild halls
			; EXCLUDED: 15 explorable-area-only items (Candy Apple, Candy Corn, Golden Egg, 
			; Honeycomb, Pumpkin Cookie, Refined Jelly, Pumpkin Pie, War Supplies, 
			; Wintergreen/Rainbow/Peppermint Candy Canes, Birthday Cupcake, Rock Candies)
			Local $iTotalSize = $GC_AI_ALL_SWEET[0]
			ReDim $aItemModelIDs[$iTotalSize]
			
			; Fill array with outpost-usable sweet items only
			For $i = 1 To $GC_AI_ALL_SWEET[0]
				$aItemModelIDs[$iModelIdx] = $GC_AI_ALL_SWEET[$i]
				$iModelIdx += 1
			Next
	EndSwitch
	
	; Search inventory bags (1-4) for items with matching ModelIDs
	; Use bag constants: BACKPACK=1, BELT_POUCH=2, BAG1=3, BAG2=4
	Local $aBags[4] = [$GC_I_INVENTORY_BACKPACK, $GC_I_INVENTORY_BELT_POUCH, $GC_I_INVENTORY_BAG1, $GC_I_INVENTORY_BAG2]
	
	For $b = 0 To UBound($aBags) - 1
		Local $bag = $aBags[$b]
		Local $bagPtr = Item_GetBagPtr($bag)
		If $bagPtr = 0 Then ContinueLoop
		
		Local $maxSlots = Item_GetBagInfo($bag, "Slots")
		For $slot = 1 To $maxSlots
			; Use GwAu3 function Item_GetItemBySlot which takes bag number and slot
			Local $itemPtr = Item_GetItemBySlot($bag, $slot)
			If $itemPtr = 0 Then ContinueLoop
			
			Local $modelID = Item_GetItemInfoByPtr($itemPtr, "ModelID")
			; Check if this ModelID is in our category list - Use _ArraySearch for O(n) instead of O(n²)
			Local $iFound = _ArraySearch($aItemModelIDs, $modelID)
			If $iFound >= 0 Then
				; Store item info: [ItemPtr, ModelID, Points]
				Local $iIndex = UBound($aItems)
				ReDim $aItems[$iIndex + 1][3]
				$aItems[$iIndex][0] = $itemPtr
				$aItems[$iIndex][1] = $modelID
				$aItems[$iIndex][2] = GetItemPoints($modelID)
			EndIf
		Next
	Next
	
	Return $aItems
EndFunc

Func SortItemsByPoints($aItems)
	; Sort items by point value (lowest first) using built-in sort
	; $aItems structure: [ItemPtr, ModelID, Points]
	; Sort by column 2 (Points) in ascending order
	_ArraySort($aItems, 0, 0, 0, 2)
	Return $aItems
EndFunc

Func UseItem($itemPtr)
	; Use an item using GwAu3 function
	; Returns True if successful, False otherwise
	
	If $itemPtr = 0 Then
		LogMessage("Error: Invalid item pointer (0)")
		Return False
	EndIf
	
	; Verify item still exists before using
	Local $modelID = Item_GetItemInfoByPtr($itemPtr, "ModelID")
	If $modelID = 0 Then
		LogMessage("Warning: Item no longer exists in inventory")
		Return False
	EndIf
	
	; Use GwAu3 function
	Item_UseItem($itemPtr)
	
	; Wait a bit for item to be used
	Sleep(50)
	
	Return True
EndFunc
#EndRegion Item Functions

#Region Main
; Initialize point mapping
InitializePointMapping()

; Create GUI
CreateGUI()

; Main event loop
Local $iLastStatusUpdate = TimerInit()
Local $iLastTitleSync = TimerInit()
While 1
	; Update status display periodically
	If TimerDiff($iLastStatusUpdate) >= $STATUS_UPDATE_INTERVAL_MS Then
		UpdateStatusDisplay()
		$iLastStatusUpdate = TimerInit()
	EndIf
	
	; Sync title points from game periodically
	If $BotRunning And $BotInitialized And TimerDiff($iLastTitleSync) >= $TITLE_SYNC_INTERVAL_MS Then
		SyncTitlePointsFromGame()
		$iLastTitleSync = TimerInit()
	EndIf
	
	If $BotRunning And $BotInitialized Then
		; Check if game is loaded
		; Map_MapIsLoaded() only returns True once per map load event, so use a more reliable check
		; Check: player agent exists, agents are loaded, and we're not in loading state
		Local $playerAgent = Agent_GetAgentPtr(-2)
		Local $instanceType = Map_GetInstanceInfo("Type")
		Local $maxAgents = Agent_GetMaxAgents()
		
		; Validate game state - ensure all critical values are valid
		If $playerAgent = 0 Or $maxAgents = 0 Or $instanceType = 2 Then
			LogMessage("Game client disconnected or map not loaded")
			StopBot()
		Else
			; Check if we have a current category to process
			If $CurrentCategoryIndex < 0 Then
				; No current category - should not happen in normal flow
				LogMessage("Error: No category selected for processing")
				StopBot()
			Else
				; Get items of current category from inventory
				Local $aItems = GetCategoryItemsInInventory($CurrentCategoryIndex)
				
				; Check if current category is complete
				Local $bCategoryComplete = False
				Local $sReason = ""
				
				If UBound($aItems) = 0 Then
					$bCategoryComplete = True
					$sReason = "Run out of items"
				ElseIf $g_iTitleCurrentPoints[$CurrentCategoryIndex] >= $MAX_POINTS Then
					$bCategoryComplete = True
					$sReason = "Threshold reached (10,000 points)"
				EndIf
				
				If $bCategoryComplete Then
					; Current category is complete
					LogMessage($sReason & " for " & GetCategoryName($CurrentCategoryIndex) & " category")
					
					; Try to start next category
					If StartNextCategory() Then
						; Successfully started next category - continue processing
						ContinueLoop
					Else
						; No more categories - stop bot
						LogMessage("All selected categories completed")
						StopBot()
					EndIf
				Else
					; Process current category
					; Sort items by points (lowest first)
					$aItems = SortItemsByPoints($aItems)
					
					; Verify array is valid after sorting
					If UBound($aItems) = 0 Then
						LogMessage("Error: Item array invalid after sorting")
						StopBot()
						ContinueLoop
					EndIf
					
					; Use first item
					Local $itemPtr = $aItems[0][0]
					Local $modelID = $aItems[0][1]
					Local $points = $aItems[0][2]
					
					If UseItem($itemPtr) Then
						; Item used successfully
						$ItemsUsed += 1
						
						; Log item used
						LogMessage("Used item (ModelID: " & $modelID & ") (" & $points & "pt)")
						
						; $CurrentCategoryIndex directly maps to: [0]=Drunkard, [1]=Party, [2]=Sweet
						Local $titleIdx = $CurrentCategoryIndex
						
						; Validate title index
						If $titleIdx < 0 Or $titleIdx > 2 Then
							LogMessage("Error: Invalid title index " & $titleIdx)
							StopBot()
							ContinueLoop
						EndIf
						
						; Check if item used was a tonic
						; If so, add cooldown delay before using another tonic
						If IsTonic($modelID) Then
							LogMessage("Tonic used - waiting " & $TONIC_COOLDOWN_MS & "ms before next item")
							Sleep($TONIC_COOLDOWN_MS)
						EndIf
					Else
						; Item usage failed - skip
						LogMessage("Item (ModelID: " & $modelID & ") cannot be used here - skipping")
					EndIf
					
					Sleep(100)
				EndIf
			EndIf
		EndIf
	EndIf
	Sleep(50) ; Small delay to prevent CPU spinning
WEnd
#EndRegion Main