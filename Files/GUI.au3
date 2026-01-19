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
	$hGui = GUICreate("Item Spammer v2", 320, 450)
	
	; Character selection
	GUICtrlCreateLabel("Character:", 5, 5, 60, 17)
	$cbx_char_select = GUICtrlCreateCombo("", 70, 3, 245, 25, BitOR($CBS_DROPDOWN, $CBS_AUTOHSCROLL))
	GUICtrlSetData($cbx_char_select, Scanner_GetLoggedCharNames())
	GUICtrlSetOnEvent($cbx_char_select, "OnCharacterChange")
	
	; Category selection
	GUICtrlCreateLabel("Choose:", 5, 35, 60, 17)
	$radio_alcohol = GUICtrlCreateRadio("Alcohol", 70, 33, 60, 17)
	GUICtrlSetOnEvent($radio_alcohol, "OnCategoryChange")
	$radio_party = GUICtrlCreateRadio("Party", 135, 33, 60, 17)
	GUICtrlSetOnEvent($radio_party, "OnCategoryChange")
	$radio_sweet = GUICtrlCreateRadio("Sweet", 200, 33, 60, 17)
	GUICtrlSetOnEvent($radio_sweet, "OnCategoryChange")
	
	; Start/Stop button
	$btn_start = GUICtrlCreateButton("Start", 5, 60, 310, 25)
	GUICtrlSetFont($btn_start, 10)
	GUICtrlSetOnEvent($btn_start, "OnStartStop")
	GUICtrlSetState($btn_start, $GUI_DISABLE)
	
	; Table headers
	Local $yPos = 115
	Local $aHeaderCtrls[4]
	$aHeaderCtrls[0] = GUICtrlCreateLabel("Title", 10, $yPos, 90, 17)
	$aHeaderCtrls[1] = GUICtrlCreateLabel("Current", 105, $yPos, 65, 17)
	$aHeaderCtrls[2] = GUICtrlCreateLabel("Session Gain", 175, $yPos, 100, 17)
	
	; Separator line (using label as divider)
	$yPos += 18
	GUICtrlCreateLabel("", 5, $yPos, 310, 1, $SS_ETCHEDHORZ)
	
	; Row 1: Drunkard
	$yPos += 8
	GUICtrlCreateLabel("Drunkard", 10, $yPos, 90, 17)
	$lbl_drunkard_current = GUICtrlCreateLabel("0", 105, $yPos, 65, 17)
	$lbl_drunkard_gained = GUICtrlCreateLabel("+0", 175, $yPos, 100, 17)
	GUICtrlSetColor($lbl_drunkard_gained, 0x00AA00) ; Green color
	
	; Row 2: Party Animal
	$yPos += 20
	GUICtrlCreateLabel("Party Animal", 10, $yPos, 90, 17)
	$lbl_party_current = GUICtrlCreateLabel("0", 105, $yPos, 65, 17)
	$lbl_party_gained = GUICtrlCreateLabel("+0", 175, $yPos, 100, 17)
	GUICtrlSetColor($lbl_party_gained, 0x00AA00) ; Green color
	
	; Row 3: Sweet Tooth
	$yPos += 20
	GUICtrlCreateLabel("Sweet Tooth", 10, $yPos, 90, 17)
	$lbl_sweet_current = GUICtrlCreateLabel("0", 105, $yPos, 65, 17)
	$lbl_sweet_gained = GUICtrlCreateLabel("+0", 175, $yPos, 100, 17)
	GUICtrlSetColor($lbl_sweet_gained, 0x00AA00) ; Green color
	
	; Stats display
	$yPos += 30
	GUICtrlCreateLabel("Items Used:", 10, $yPos, 80, 17)
	$lbl_items_used = GUICtrlCreateLabel("0", 180, $yPos, 50, 17)
	
	$yPos += 20
	GUICtrlCreateLabel("Runtime:", 10, $yPos, 50, 17)
	$lbl_time_running = GUICtrlCreateLabel("00:00:00", 180, $yPos, 80, 17)
	
	; Log window
	$yPos += 25
	$aHeaderCtrls[3] = GUICtrlCreateLabel("Log:", 5, $yPos, 30, 17)
	
	; Set bold font for all header labels
	For $i = 0 To 3
		GUICtrlSetFont($aHeaderCtrls[$i], 8, 600)
	Next
	
	$yPos += 20
	$lbl_status = GUICtrlCreateEdit("", 5, $yPos, 310, 180, BitOR($ES_READONLY, $WS_VSCROLL, $ES_AUTOVSCROLL))
	
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
	Local $aCurrentLabels[3] = [$lbl_drunkard_current, $lbl_party_current, $lbl_sweet_current]
	Local $aGainedLabels[3] = [$lbl_drunkard_gained, $lbl_party_gained, $lbl_sweet_gained]
	
	For $i = 0 To 2
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