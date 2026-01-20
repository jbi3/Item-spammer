#cs =============================================================================================================================
	Item-Spammer version 1.0.1
	Author: Arca
	Status: Public
    Purpose: It helps ease the pain of spamming items for the Drunkard, Party Animal and Sweet Tooth titles.

    Features:
	    - Automatic use of items in player's inventory with randomized delays for 3 categories: Alcohol, Sweet and Party.
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

; Category and points
Global $SelectedCategory = -1 ; -1 = none selected

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

; Validated delay constants (validated once at startup for performance)
Global $g_iValidatedMinDelay = 0
Global $g_iValidatedMaxDelay = 0
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
Func StartBot()
	If $CurrentCharacter = "" Then
		LogMessage("Error: Please select a character")
		Return
	EndIf
	
	If $SelectedCategory < 0 Then
		LogMessage("Error: Start by choosing a category")
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
	
	Local $sCategory = ""
	Switch $SelectedCategory
		Case $CATEGORY_ALCOHOL  ; 0
			$sCategory = "Alcohol"
		Case $CATEGORY_PARTY    ; 1
			$sCategory = "Party"
		Case $CATEGORY_SWEET    ; 2
			$sCategory = "Sweet"
	EndSwitch
	
	LogMessage("Script started - " & $sCategory & " category selected")
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

; Validate delay constants once at startup for performance
$g_iValidatedMinDelay = ($MIN_DELAY < 50) ? 50 : $MIN_DELAY
$g_iValidatedMaxDelay = ($MAX_DELAY > 60000) ? 60000 : $MAX_DELAY
If $g_iValidatedMinDelay > $g_iValidatedMaxDelay Then $g_iValidatedMinDelay = $g_iValidatedMaxDelay

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
			; Get items of selected category from inventory
			Local $aItems = GetCategoryItemsInInventory($SelectedCategory)
			
			; If no items, stop
			If UBound($aItems) = 0 Then
				LogMessage("Run out of items")
				StopBot()
			Else
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
					
					; $SelectedCategory directly maps to: [0]=Drunkard, [1]=Party, [2]=Sweet
					Local $titleIdx = $SelectedCategory
					
					; Validate title index
					If $titleIdx < 0 Or $titleIdx > 2 Then
						LogMessage("Error: Invalid title index " & $titleIdx)
						StopBot()
						ContinueLoop
					EndIf
					
					; Check threshold - for the active category being used
					If $g_iTitleCurrentPoints[$titleIdx] >= $MAX_POINTS Then
						LogMessage("Threshold reached (10,000 points) for selected category")
						StopBot()
					Else
						; Check if item used was a tonic
						; If so, add cooldown delay before using another tonic
						If IsTonic($modelID) Then
							LogMessage("Tonic used - waiting " & $TONIC_COOLDOWN_MS & "ms before next item")
							Sleep($TONIC_COOLDOWN_MS)
						EndIf
					EndIf
				Else
					; Item usage failed - skip
					LogMessage("Item (ModelID: " & $modelID & ") cannot be used here - skipping")
				EndIf
				
				; Random delay - use pre-validated delay constants
				Sleep(Random($g_iValidatedMinDelay, $g_iValidatedMaxDelay, 1))
			EndIf
		EndIf
	EndIf
	Sleep(50) ; Small delay to prevent CPU spinning
WEnd
#EndRegion Main