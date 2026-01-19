#include-once

#Region Global GUI Variables
; GUI controls
Global $hGui = 0
Global $cbx_char_select = 0
Global $radio_alcohol = 0
Global $radio_sweet = 0
Global $radio_party = 0
Global $btn_start = 0
Global $lbl_status = 0
Global $lbl_items_used = 0
Global $lbl_time_running = 0

; Title name labels (with level display)
Global $lbl_drunkard_name = 0
Global $lbl_party_name = 0
Global $lbl_sweet_name = 0

; Title progress display labels (Current Points)
Global $lbl_drunkard_current = 0
Global $lbl_party_current = 0
Global $lbl_sweet_current = 0

; Title progress display labels (Session Gains)
Global $lbl_drunkard_gained = 0
Global $lbl_party_gained = 0
Global $lbl_sweet_gained = 0
#EndRegion Global GUI Variables

#Region GUI Creation
Func CreateGUI()
	$hGui = GUICreate("Item Spammer", 320, 510)
	
	Local $yPos = 5
	
	; ===== SESSION SECTION =====
	GUICtrlCreateGroup("Session", 5, $yPos, 310, 145)
	
	; Character selection
	$yPos += 20
	GUICtrlCreateLabel("Choose a character", 15, $yPos, 290, 17)
	GUICtrlSetFont(-1, 8, 600) ; Bold
	$yPos += 18
	$cbx_char_select = GUICtrlCreateCombo("", 15, $yPos, 290, 25, BitOR($CBS_DROPDOWN, $CBS_AUTOHSCROLL))
	GUICtrlSetData($cbx_char_select, Scanner_GetLoggedCharNames())
	GUICtrlSetOnEvent($cbx_char_select, "OnCharacterChange")
	
	; Category selection
	$yPos += 30
	GUICtrlCreateLabel("Choose a category", 15, $yPos, 290, 17)
	GUICtrlSetFont(-1, 8, 600) ; Bold
	$yPos += 18
	$radio_alcohol = GUICtrlCreateRadio("Alcohol", 15, $yPos, 70, 17)
	GUICtrlSetOnEvent($radio_alcohol, "OnCategoryChange")
	$radio_party = GUICtrlCreateRadio("Party", 95, $yPos, 70, 17)
	GUICtrlSetOnEvent($radio_party, "OnCategoryChange")
	$radio_sweet = GUICtrlCreateRadio("Sweet", 175, $yPos, 70, 17)
	GUICtrlSetOnEvent($radio_sweet, "OnCategoryChange")
	
	; Start/Stop button
	$yPos += 25
	$btn_start = GUICtrlCreateButton("Start", 15, $yPos, 290, 25)
	GUICtrlSetFont($btn_start, 10)
	GUICtrlSetOnEvent($btn_start, "OnStartStop")
	GUICtrlSetState($btn_start, $GUI_DISABLE)
	
	; Close Session group
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	
	; ===== TITLE PROGRESS SECTION =====
	$yPos += 35
	GUICtrlCreateGroup("Title Progress", 5, $yPos, 310, 115)
	
	; Table headers
	$yPos += 20
	Local $aHeaderCtrls[4]
	$aHeaderCtrls[0] = GUICtrlCreateLabel("Title", 20, $yPos, 90, 17)
	$aHeaderCtrls[1] = GUICtrlCreateLabel("Current", 115, $yPos, 65, 17)
	$aHeaderCtrls[2] = GUICtrlCreateLabel("Session Gain", 185, $yPos, 100, 17)
	
	; Separator line (using label as divider)
	$yPos += 18
	GUICtrlCreateLabel("", 15, $yPos, 290, 1, $SS_ETCHEDHORZ)
	
	; Row 1: Drunkard
	$yPos += 8
	$lbl_drunkard_name = GUICtrlCreateLabel("Drunkard (0)", 20, $yPos, 90, 17)
	$lbl_drunkard_current = GUICtrlCreateLabel("0", 115, $yPos, 65, 17)
	$lbl_drunkard_gained = GUICtrlCreateLabel("+0", 185, $yPos, 100, 17)
	GUICtrlSetColor($lbl_drunkard_gained, 0x00AA00) ; Green color
	
	; Row 2: Party Animal
	$yPos += 20
	$lbl_party_name = GUICtrlCreateLabel("Party Animal (0)", 20, $yPos, 90, 17)
	$lbl_party_current = GUICtrlCreateLabel("0", 115, $yPos, 65, 17)
	$lbl_party_gained = GUICtrlCreateLabel("+0", 185, $yPos, 100, 17)
	GUICtrlSetColor($lbl_party_gained, 0x00AA00) ; Green color
	
	; Row 3: Sweet Tooth
	$yPos += 20
	$lbl_sweet_name = GUICtrlCreateLabel("Sweet Tooth (0)", 20, $yPos, 90, 17)
	$lbl_sweet_current = GUICtrlCreateLabel("0", 115, $yPos, 65, 17)
	$lbl_sweet_gained = GUICtrlCreateLabel("+0", 185, $yPos, 100, 17)
	GUICtrlSetColor($lbl_sweet_gained, 0x00AA00) ; Green color
	
	; Close Title Progress group
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	
	; ===== STATISTICS SECTION (Stats + Log) =====
	$yPos += 30
	GUICtrlCreateGroup("Statistics", 5, $yPos, 310, 260)
	
	$yPos += 20
	GUICtrlCreateLabel("Items Used:", 20, $yPos, 80, 17)
	$lbl_items_used = GUICtrlCreateLabel("0", 190, $yPos, 50, 17)
	
	$yPos += 20
	GUICtrlCreateLabel("Runtime:", 20, $yPos, 50, 17)
	$lbl_time_running = GUICtrlCreateLabel("00:00:00", 190, $yPos, 80, 17)
	
	; Log window
	$yPos += 30
	GUICtrlCreateLabel("Log:", 20, $yPos, 30, 17)
	
	$yPos += 20
	$lbl_status = GUICtrlCreateEdit("", 15, $yPos, 290, 155, BitOR($ES_READONLY, $WS_VSCROLL, $ES_AUTOVSCROLL))
	
	; Close Statistics group
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	
	; Set bold font for table header labels
	For $i = 0 To 2
		GUICtrlSetFont($aHeaderCtrls[$i], 8, 600)
	Next
	
	GUISetOnEvent($GUI_EVENT_CLOSE, "OnExit")
	GUISetState(@SW_SHOW)
EndFunc
#EndRegion GUI Creation

#Region Event Handlers
Func OnCharacterChange()
	$CurrentCharacter = GUICtrlRead($cbx_char_select)
	If $CurrentCharacter <> "" Then
		UpdateStartButtonState()
	EndIf
EndFunc

Func OnCategoryChange()
	Local $radio = @GUI_CtrlId
	If $radio = $radio_alcohol Then
		$SelectedCategory = $CATEGORY_ALCOHOL  ; 0 = Drunkard
	ElseIf $radio = $radio_party Then
		$SelectedCategory = $CATEGORY_PARTY    ; 1 = Party Animal
	ElseIf $radio = $radio_sweet Then
		$SelectedCategory = $CATEGORY_SWEET    ; 2 = Sweet Tooth
	EndIf
	UpdateStartButtonState()
EndFunc

Func OnStartStop()
	If $BotRunning Then
		StopBot()
	Else
		StartBot()
	EndIf
EndFunc

Func OnExit()
	If $BotRunning Then
		StopBot()
	EndIf
	Exit
EndFunc

Func UpdateStartButtonState()
	Local $bCanStart = ($CurrentCharacter <> "" And $SelectedCategory >= 0)
	If $BotInitialized Then
		If $BotRunning Then
			GUICtrlSetData($btn_start, "Stop")
			GUICtrlSetState($btn_start, $GUI_ENABLE)
		Else
			GUICtrlSetData($btn_start, "Start")
			GUICtrlSetState($btn_start, $GUI_ENABLE)
		EndIf
	Else
		GUICtrlSetData($btn_start, "Start")
		GUICtrlSetState($btn_start, $bCanStart ? $GUI_ENABLE : $GUI_DISABLE)
	EndIf
EndFunc
#EndRegion Event Handlers

#Region Display Functions
Func LogMessage($sMessage)
	Local $sTimestamp = "[" & StringFormat("%02d:%02d:%02d", @HOUR, @MIN, @SEC) & "]"
	Local $sLogEntry = $sTimestamp & " " & $sMessage & @CRLF
	GUICtrlSetData($lbl_status, GUICtrlRead($lbl_status) & $sLogEntry)
	_GUICtrlEdit_Scroll($lbl_status, $SB_SCROLLCARET)
EndFunc

Func UpdateStatusDisplay()
	; Update title progress display using loops for DRY principle
	Local $aTitleNames[3] = ["Drunkard", "Party Animal", "Sweet Tooth"]
	Local $aNameLabels[3] = [$lbl_drunkard_name, $lbl_party_name, $lbl_sweet_name]
	Local $aCurrentLabels[3] = [$lbl_drunkard_current, $lbl_party_current, $lbl_sweet_current]
	Local $aGainedLabels[3] = [$lbl_drunkard_gained, $lbl_party_gained, $lbl_sweet_gained]
	
	For $i = 0 To 2
		; Update title name with level
		Local $iLevel = GetTitleLevel($g_iTitleCurrentPoints[$i])
		GUICtrlSetData($aNameLabels[$i], $aTitleNames[$i] & " (" & $iLevel & ")")
		
		; Update current points and session gains
		GUICtrlSetData($aCurrentLabels[$i], $g_iTitleCurrentPoints[$i])
		GUICtrlSetData($aGainedLabels[$i], "+" & $g_iTitlePointsGained[$i])
	Next
	
	; Update items used
	GUICtrlSetData($lbl_items_used, $ItemsUsed)
	
	; Update time - use frozen time if stopped, calculate live time if running
	If $FinalRuntime <> "" Then
		; Bot has stopped - display frozen final runtime
		GUICtrlSetData($lbl_time_running, $FinalRuntime)
	ElseIf $StartTime > 0 Then
		; Bot is running - show accumulated + current run time
		Local $iTotalMS = $AccumulatedRuntime + TimerDiff($StartTime)
		Local $sTime = FormatMillisecondsAsTime($iTotalMS)
		GUICtrlSetData($lbl_time_running, $sTime)
	EndIf
EndFunc
#EndRegion Display Functions