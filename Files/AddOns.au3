#include-once

#Region Constants
; Category constants
; Title array: [0]=Drunkard, [1]=Party Animal, [2]=Sweet Tooth
Global Const $CATEGORY_ALCOHOL = 0
Global Const $CATEGORY_PARTY = 1
Global Const $CATEGORY_SWEET = 2

; Settings
Global Const $MAX_POINTS = 10000
Global Const $MIN_DELAY = 100
Global Const $MAX_DELAY = 200

; Timing constants
Global Const $TONIC_COOLDOWN_MS = 6000
Global Const $STATUS_UPDATE_INTERVAL_MS = 1000
Global Const $TITLE_SYNC_INTERVAL_MS = 2000

; Party Tonics - 2 points (19 items)
Global Const $GC_AI_PARTY_TONICS_2PT[20] = [19, _
	$GC_I_MODELID_BEETLE_JUICE_TONIC, _
	$GC_I_MODELID_COTTONTAIL_TONIC, _
	$GC_I_MODELID_FROSTY_TONIC, _
	$GC_I_MODELID_MISCHIEVOUS_TONIC, _
	$GC_I_MODELID_TRANSMOGRIFIER_TONIC, _
	$GC_I_MODELID_YULETIDE_TONIC, _
	$GC_I_MODELID_CEREBRAL_TONIC, _
	$GC_I_MODELID_SEARING_TONIC, _
	$GC_I_MODELID_ABYSSAL_TONIC, _
	$GC_I_MODELID_UNSEEN_TONIC, _
	$GC_I_MODELID_PHANTASMAL_TONIC, _
	$GC_I_MODELID_AUTOMATONIC_TONIC, _
	$GC_I_MODELID_BOREAL_TONIC, _
	$GC_I_MODELID_TRAPDOOR_TONIC, _
	$GC_I_MODELID_MACABRE_TONIC, _
	$GC_I_MODELID_SKELETONIC_TONIC, _
	$GC_I_MODELID_GELATINOUS_TONIC, _
	$GC_I_MODELID_ABOMINABLE_TONIC, _
	$GC_I_MODELID_SINISTER_AUTOMATONIC_TONIC]

; All Tonics - Consolidated list for fast IsTonic() lookup (23 items total)
Global Const $GC_AI_ALL_TONICS[24] = [23, _
	$GC_I_MODELID_BEETLE_JUICE_TONIC, _
	$GC_I_MODELID_COTTONTAIL_TONIC, _
	$GC_I_MODELID_FROSTY_TONIC, _
	$GC_I_MODELID_MISCHIEVOUS_TONIC, _
	$GC_I_MODELID_TRANSMOGRIFIER_TONIC, _
	$GC_I_MODELID_YULETIDE_TONIC, _
	$GC_I_MODELID_CEREBRAL_TONIC, _
	$GC_I_MODELID_SEARING_TONIC, _
	$GC_I_MODELID_ABYSSAL_TONIC, _
	$GC_I_MODELID_UNSEEN_TONIC, _
	$GC_I_MODELID_PHANTASMAL_TONIC, _
	$GC_I_MODELID_AUTOMATONIC_TONIC, _
	$GC_I_MODELID_BOREAL_TONIC, _
	$GC_I_MODELID_TRAPDOOR_TONIC, _
	$GC_I_MODELID_MACABRE_TONIC, _
	$GC_I_MODELID_SKELETONIC_TONIC, _
	$GC_I_MODELID_GELATINOUS_TONIC, _
	$GC_I_MODELID_ABOMINABLE_TONIC, _
	$GC_I_MODELID_SINISTER_AUTOMATONIC_TONIC, _
	$GC_I_MODELID_MINUTELY_MAD_KING_TONIC, _
	$GC_I_MODELID_ZAISHEN_TONIC, _
	$GC_I_MODELID_MYSTERIOUS_TONIC, _
	$GC_I_MODELID_SPOOKY_TONIC]
#EndRegion Constants

#Region Global Variables
; Point mapping (ModelID -> Points)
Global $g_PointMapping[77][2] ; Will be populated on initialization
#EndRegion Global Variables

#Region Point Mapping Functions
Func InitializePointMapping()
	; Initialize point mapping using existing GwAu3 constants
	; This maps ModelID -> Point Value for sorting
	
	Local $i = 0
	
	; Alcohol items - 1 point (11 items)
	For $j = 1 To $GC_AI_ONEPOINT_ALCOHOL[0]
		$g_PointMapping[$i][0] = $GC_AI_ONEPOINT_ALCOHOL[$j]
		$g_PointMapping[$i][1] = 1
		$i += 1
	Next
	
	; Alcohol items - 3 points (7 items)
	For $j = 1 To $GC_AI_THREEPOINT_ALCOHOL[0]
		$g_PointMapping[$i][0] = $GC_AI_THREEPOINT_ALCOHOL[$j]
		$g_PointMapping[$i][1] = 3
		$i += 1
	Next
	
	; Alcohol items - 50 points (1 item)
	For $j = 1 To $GC_AI_FIFTYPOINT_ALCOHOL[0]
		$g_PointMapping[$i][0] = $GC_AI_FIFTYPOINT_ALCOHOL[$j]
		$g_PointMapping[$i][1] = 50
		$i += 1
	Next
	
	; Party items - 1 point (6 items)
	; Note: Array has incorrect count in [0], use UBound instead
	For $j = 1 To UBound($GC_AI_SPAMMABLE_PARTY) - 1
		$g_PointMapping[$i][0] = $GC_AI_SPAMMABLE_PARTY[$j]
		$g_PointMapping[$i][1] = 1
		$i += 1
	Next
	; Ghost-in-the-Box (1 point)
	$g_PointMapping[$i][0] = $GC_I_MODELID_GHOST_IN_THE_BOX
	$g_PointMapping[$i][1] = 1
	$i += 1
	
	; Party items - 2 points (19 tonics) - Use global constant
	For $j = 1 To $GC_AI_PARTY_TONICS_2PT[0]
		$g_PointMapping[$i][0] = $GC_AI_PARTY_TONICS_2PT[$j]
		$g_PointMapping[$i][1] = 2
		$i += 1
	Next
	
	; Party items - 3 points (3 items)
	$g_PointMapping[$i][0] = $GC_I_MODELID_CRATE_OF_FIREWORKS
	$g_PointMapping[$i][1] = 3
	$i += 1
	$g_PointMapping[$i][0] = $GC_I_MODELID_MINUTELY_MAD_KING_TONIC
	$g_PointMapping[$i][1] = 3
	$i += 1
	$g_PointMapping[$i][0] = $GC_I_MODELID_ZAISHEN_TONIC
	$g_PointMapping[$i][1] = 3
	$i += 1
	
	; Party items - 5 points (1 item)
	$g_PointMapping[$i][0] = $GC_I_MODELID_MYSTERIOUS_TONIC
	$g_PointMapping[$i][1] = 5
	$i += 1
	
	; Party items - 7 points (1 item)
	$g_PointMapping[$i][0] = $GC_I_MODELID_DISCO_BALL
	$g_PointMapping[$i][1] = 7
	$i += 1
	
	; Party items - 25 points (1 item)
	$g_PointMapping[$i][0] = $GC_I_MODELID_SPOOKY_TONIC
	$g_PointMapping[$i][1] = 25
	$i += 1
	
	; Party items - 50 points (1 item)
	$g_PointMapping[$i][0] = $GC_I_MODELID_PARTY_BEACON
	$g_PointMapping[$i][1] = 50
	$i += 1
	
	; Sweet items - 1 point (13 items)
	Local $a_Sweet1Pts[13] = [$GC_I_MODELID_CANDY_APPLE, $GC_I_MODELID_CANDY_CORN, $GC_I_MODELID_FRUITCAKE, _
		$GC_I_MODELID_GOLDEN_EGG, $GC_I_MODELID_HONEYCOMB, $GC_I_MODELID_MANDRAGOR_ROOT_CAKE, _
		$GC_I_MODELID_PUMPKIN_COOKIE, $GC_I_MODELID_REFINED_JELLY, $GC_I_MODELID_PUMPKIN_PIE, _
		$GC_I_MODELID_SUGARY_BLUE_DRINK, $GC_I_MODELID_WAR_SUPPLIES, $GC_I_MODELID_WINTERGREEN_CC, _
		$GC_I_MODELID_RAINBOW_CC]
	For $j = 0 To UBound($a_Sweet1Pts) - 1
		$g_PointMapping[$i][0] = $a_Sweet1Pts[$j]
		$g_PointMapping[$i][1] = 1
		$i += 1
	Next
	
	; Sweet items - 2 points (5 items)
	Local $a_Sweet2Pts[5] = [$GC_I_MODELID_PEPPERMINT_CC, $GC_I_MODELID_CUPCAKE, $GC_I_MODELID_CHOCOLATE_BUNNY, _
		$GC_I_MODELID_RED_BEAN_CAKE, $GC_I_MODELID_JAR_OF_HONEY]
	For $j = 0 To UBound($a_Sweet2Pts) - 1
		$g_PointMapping[$i][0] = $a_Sweet2Pts[$j]
		$g_PointMapping[$i][1] = 2
		$i += 1
	Next
	
	; Sweet items - 3 points (4 items)
	Local $a_Sweet3Pts[4] = [$GC_I_MODELID_CREME_BRULEE, $GC_I_MODELID_KRYTAN_LOKUM, _
		$GC_I_MODELID_MINI_TREATS_OF_PURITY, $GC_I_MODELID_GREEN_ROCK]
	For $j = 0 To UBound($a_Sweet3Pts) - 1
		$g_PointMapping[$i][0] = $a_Sweet3Pts[$j]
		$g_PointMapping[$i][1] = 3
		$i += 1
	Next
	
	; Sweet items - 5 points (1 item)
	$g_PointMapping[$i][0] = $GC_I_MODELID_BLUE_ROCK
	$g_PointMapping[$i][1] = 5
	$i += 1
	
	; Sweet items - 7 points (1 item)
	$g_PointMapping[$i][0] = $GC_I_MODELID_RED_ROCK
	$g_PointMapping[$i][1] = 7
	$i += 1
	
	; Sweet items - 50 points (1 item)
	$g_PointMapping[$i][0] = $GC_I_MODELID_DELICIOUS_CAKE
	$g_PointMapping[$i][1] = 50
	$i += 1
	
	; Sort array by ModelID (column 0) for binary search optimization
	_ArraySort($g_PointMapping, 0, 0, 0, 0)
EndFunc

Func GetItemPoints($aModelID)
	; Lookup point value for a given ModelID using binary search (O(log n))
	; Array is sorted by ModelID in InitializePointMapping()
	Local $iFound = _ArrayBinarySearch($g_PointMapping, $aModelID, 0, 0, 0)
	If $iFound >= 0 Then
		Return $g_PointMapping[$iFound][1]
	EndIf
	Return 0 ; Not found
EndFunc

Func IsTonic($aModelID)
	; Check if a ModelID corresponds to a tonic using _ArraySearch (O(n) but optimized)
	; Uses consolidated list of all 23 tonics
	Local $iFound = _ArraySearch($GC_AI_ALL_TONICS, $aModelID, 1)
	Return ($iFound >= 0)
EndFunc
#EndRegion Point Mapping Functions

#Region Utility Functions
Func FormatMillisecondsAsTime($iMilliseconds)
	; Converts milliseconds to formatted time string HH:MM:SS
	; Handles negative values and clamps to valid ranges
	
	If $iMilliseconds < 0 Then $iMilliseconds = 0
	
	Local $iElapsed = $iMilliseconds / 1000 ; convert to seconds
	Local $iHours = Int($iElapsed / 3600)
	Local $iMinutes = Int(($iElapsed - $iHours * 3600) / 60)
	Local $iSeconds = Int($iElapsed - $iHours * 3600 - $iMinutes * 60)
	
	; Clamp values to valid ranges
	If $iHours < 0 Then $iHours = 0
	If $iMinutes < 0 Then $iMinutes = 0
	If $iSeconds < 0 Then $iSeconds = 0
	
	Return StringFormat("%02d:%02d:%02d", $iHours, $iMinutes, $iSeconds)
EndFunc

Func GetTitleLevel($iPoints)
	; Calculate title level based on points
	; 0-999 = level 0 (no title)
	; 1000-9999 = level 1
	; 10000+ = level 2 (max)
	If $iPoints < 1000 Then
		Return 0
	ElseIf $iPoints < 10000 Then
		Return 1
	Else
		Return 2
	EndIf
EndFunc
#EndRegion Utility Functions