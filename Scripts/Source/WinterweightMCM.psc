ScriptName WinterweightMCM extends SKI_ConfigBase
{
AUTHOR: Gaz
PURPOSE: Provides my Weight Gain mods' MCM.
}

import Winterweight_JCDomain
import Logging

WinterweightCore Property Core Auto
Actor Property PlayerRef Auto

String MODKEY = "Winterweight.esp"
String PREFIX = "WinterweightMCM"
Actor Target
int optionsMap
int ValueOptions = -1

;/ SKI Code so I remember how version updates go.
int property CurrentVersion auto hidden

function CheckVersion()
	int version = GetVersion()
	if (CurrentVersion < version)
		OnVersionUpdateBase(version)
		OnVersionUpdate(version)
		CurrentVersion = version
	endIf
endFunction

int function GetVersion()
	return 1
endFunction

event OnVersionUpdateBase(int a_version)
endEvent

event OnVersionUpdate(int a_version)
endEvent
/;

int function GetVersion()
	return 100
endFunction

Event OnVersionUpdate(int newVersion)
	Upgrade(CurrentVersion, newVersion)
EndEvent

Function Upgrade(int oldVersion, int newVersion)
    if oldVersion < newVersion
        Core.ResetActorWeights()
    endif
endFunction

event OnConfigInit()
	Pages = new string[4]
	Pages[0] = "General Settings"
	Pages[1] = "Female Morphs"
	Pages[2] = "Male Morphs"
	Pages[3] = "Creature Morphs"
endEvent

Actor Function GetTarget()
	target = Game.GetCurrentCrosshairRef() as Actor
	if !target
		target = playerRef
	endIf

	return target
EndFunction

Event OnPageSelect(string a_page)
    optionsMap = JValue_ReleaseAndRetain(optionsMap, JIntMap_Object(), MODKEY)
EndEvent

Event OnPageReset(string page)
	optionsMap = JValue_ReleaseAndRetain(optionsMap, JIntMap_Object(), MODKEY)
	GetTarget()	;Fill target var.

	If page == "General Settings" || page == ""

		SetCursorFillMode(LEFT_TO_RIGHT)
		AddHeaderOption("Mod Status")
		AddEmptyOption()
		addToggleOptionSt("ModEnableState", "Mod Enabled", Core.ModEnabled)
		AddEmptyOption()

		AddHeaderOption("Weight Gain & Loss Eligibility")
		AddEmptyOption()
		AddToggleOptionST("PlayerEnabledState", "Player Enabled", Core.PlayerEnabled)
		AddToggleOptionST("NPCsEnabledState", "NPCs Enabled", Core.NPCsEnabled)
		
		AddHeaderOption("Weight Settings")
		AddEmptyOption()
		AddSliderOptionST("MinimumWeightState", "Minimum Weight", Core.MinimumWeight, "{2}")
		AddSliderOptionST("MaximumWeightState", "Maximum Weight", Core.MaximumWeight, "{2}")
		AddSliderOptionST("PreviewState", "Weight Preview: " +Namer(Target, true), 0.0, "{2}")
		AddToggleOptionST("WeightLossEnabledState", "Weight Loss Enabled", Core.WeightLossEnabled)
		AddSliderOptionST("WeightLossState", "Weight Loss Amount", Core.WeightLoss, "{2}")
		AddSliderOptionST("WeightRateState", "Weight Loss Rate", Core.WeightRate, "{2} In-Game Hours")
		AddSliderOptionST("IngredientGainState", "Ingredient Gain", Core.IngredientBaseGain, "{3} * Item Weight")
		AddSliderOptionST("PotionGainState", "Potion Gain", Core.PotionBaseGain, "{3} * Item Weight")
		AddSliderOptionST("FoodGainState", "Food Gain", Core.FoodBaseGain, "{3} * Item Weight")
		If Core.RefactorManager
			AddSliderOptionST("VoreGainState", "Vore Gain", Core.VoreBaseGain, "{3} / Stage")
		Else
			AddEmptyOption()
		EndIf

		AddHeaderOption("Skeleton Adjustments")
		AddEmptyOption()
		AddToggleOptionST("ArmNodeEnabledState", "Arm Node Changes", Core.ArmNodeChanges)
		AddSliderOptionST("ArmNodeFactorState", "Arm Adjustment Strength", Core.ArmNodeFactor, "{2} degrees")
		AddToggleOptionST("ThighNodeEnabledState", "Thigh Node Changes", Core.ThighNodeChanges)
		AddSliderOptionST("ThighNodeFactorState", "Thigh Adjustment Strength", Core.ThighNodeFactor, "{2} degrees")

		AddHeaderOption("High & No-Value Food")
		AddEmptyOption()
		AddTextOptionST("ShowHighValueState", "Configure High Value Food", None)
		AddTextOptionST("ShowNoValueState", "Configure No Value Food", None)

		AddHeaderOption("Companion Features")
		AddEmptyOption()
		AddToggleOptionST("DropFeedState", "Companions Eat Dropped Food", Core.DropFeeding.GetValue() as Bool)
		AddEmptyOption()

		AddHeaderOption("Normal Map Swaps")
		AddEmptyOption()
		
		AddToggleOptionST("FemaleNormalsEnabledState", "Female Normal Changes", Core.FemaleNormalChanges)
		AddEmptyOption()

		AddInputOptionST("FemaleNormal0State", "Base Female Normal", IsTextFieldFilled(Core.FemaleNormals[0]))
		AddEmptyOption()
		AddInputOptionST("FemaleNormal1State", "First Female Normal", IsTextFieldFilled(Core.FemaleNormals[1]))
		AddSliderOptionST("FemaleNormal1ThresholdState", "First Normal Threshold", Core.FemaleNormalBreakpoints[1], "{2} Weight")
		AddInputOptionST("FemaleNormal2State", "Second Female Normal", IsTextFieldFilled(Core.FemaleNormals[2]))
		AddSliderOptionST("FemaleNormal2ThresholdState", "Second Normal Threshold", Core.FemaleNormalBreakpoints[2], "{2} Weight")

		AddToggleOptionST("MaleNormalsEnabledState", "Male Normal Changes", Core.MaleNormalChanges)
		AddEmptyOption()
		AddInputOptionST("MaleNormal0State", "Base Male Normal", IsTextFieldFilled(Core.MaleNormals[0]))
		AddEmptyOption()
		AddInputOptionST("MaleNormal1State", "First Male Normal", IsTextFieldFilled(Core.MaleNormals[1]))
		AddSliderOptionST("MaleNormal1ThresholdState", "First Normal Threshold", Core.MaleNormalBreakpoints[1], "{2} Weight")
		AddInputOptionST("MaleNormal2State", "Second Male Normal", IsTextFieldFilled(Core.MaleNormals[2]))
		AddSliderOptionST("MaleNormal2ThresholdState", "Second Normal Threshold", Core.MaleNormalBreakpoints[2], "{2} Weight")

		AddHeaderOption("Setting Persistence")
		AddEmptyOption()
		AddTextOptionST("SaveSettingsState", "Save Settings", None)
		AddTextOptionST("LoadSettingsState", "Load Settings", None)

		AddHeaderOption("Debug")
		AddEmptyOption()
		AddTextOptionST("ResetOneState", "Reset " +Namer(Target, True)+  "'s Weight", None)
		AddTextOptionST("ResetAllState", "Reset All Actors Weight Values", None)
		AddSliderOptionST("SetWeightState", "Set " +Namer(Target, true)+ "'s weight", 0.0, "{2}")

	ElseIf page == "Female Morphs"

		SetCursorFillMode(LEFT_TO_RIGHT)
		addInputOptionSt("WeightAddFemaleMorphState", "Add Female Morph", "")
		AddEmptyOption()

		;Female morphs span elements 0 through 31.
		AddMorphQuads(Core.MorphStrings, Core.MorphsLow, Core.MorphsHigh, 0, 32)

	ElseIf page == "Male Morphs"

		SetCursorFillMode(LEFT_TO_RIGHT)
		addInputOptionSt("WeightAddMaleMorphState", "Add Male Morph", "")
		AddEmptyOption()

		; Male morphs span elements 32 through 63.
		AddMorphQuads(Core.MorphStrings, Core.MorphsLow, Core.MorphsHigh, 32, 32)

	ElseIf page == "Creature Morphs"
		SetCursorFillMode(LEFT_TO_RIGHT)
		addInputOptionSt("WeightAddCreatureMorphState", "Add Creature Morph", "")
		AddEmptyOption()
		; Creature morphs span elements 64 through 95.
		AddMorphQuads(Core.MorphStrings, Core.MorphsLow, Core.MorphsHigh, 64, 32)
	EndIf
EndEvent

event OnConfigClose()

	If ValueOptions >= 0
		UIListMenu menu = UIExtensions.GetMenu("UIListMenu") as UIListMenu
		bool exit = false
		while !exit
			menu.ResetMenu()
			int index = 0
			Form[] FoodItems
			Int[] EntryIndexes
			Int[] YesAnswers
			String ValueType
			If ValueOptions == 0
				FoodItems = Core.HighValueFood
				ValueType = "High Value"
			Else 
				FoodItems = Core.NoValueFood
				ValueType = "No Value"
			EndIf
			EntryIndexes = Utility.CreateIntArray(FoodItems.Length, -1)
			YesAnswers = Utility.CreateIntArray(FoodItems.Length, -1)
			menu.AddEntryItem(ValueType+ " Food List")
			int ENTRY_ADD = menu.AddEntryItem("Add New")
			while index < FoodItems.length
				If FoodItems[index] != None
					EntryIndexes[index] = menu.AddEntryItem(Namer(FoodItems[index], true), entryHasChildren = true)
					menu.AddEntryItem("Item: " +Namer(FoodItems[index], true), EntryIndexes[index])
					menu.AddEntryItem("FormID: " +Hex32(FoodItems[index].GetFormID()), EntryIndexes[index])
					YesAnswers[index] = menu.AddEntryItem("Remove from this list.", EntryIndexes[index])
				EndIf
				index += 1
			endWhile
			int ENTRY_EXIT = menu.AddEntryItem("Exit")

			menu.OpenMenu()
			Int result = menu.GetResultInt()
			if result < 0 || result == ENTRY_EXIT 
				exit = true
			elseif result == ENTRY_ADD
				Debug.MessageBox("The next Food item you consume will be added to the " +ValueType+ " Food list.")
				Core.LearnValue(ValueOptions)
				exit = true
			elseif YesAnswers.Find(result) > -1
				int iResult = EntryIndexes[YesAnswers.Find(result)]
				Int iFoodResult = EntryIndexes.Find(iResult)
				If ValueOptions == 0
					Core.HighValueFood = PapyrusUtil.RemoveForm(Core.HighValueFood, Core.HighValueFood[iFoodResult])
				Else 	
					Core.NoValueFood = PapyrusUtil.RemoveForm(Core.NoValueFood, Core.NoValueFood[iFoodResult])
				EndIf
			endif
		endWhile	
		ValueOptions = -1
	EndIf

EndEvent

String Function IsTextFieldFilled(String asString)
	If asString != ""
		Return "Filled"
	Else
		Return "Blank"
	EndIf
EndFunction

Function AddMorphQuads(String[] morphNames, float[] multLow, float[] multHigh, int offset, int count)
	int index = offset
	int endpoint = offset + count

	while index < endpoint
		if morphNames[index] != ""
			int[] quad = new int[4]
			quad[0] = index
			quad[1] = AddInputOption("Morph", morphNames[index])
			AddEmptyOption()
			quad[2] = AddInputOption("Low", multLow[index])
			quad[3] = AddInputOption("High", multHigh[index])

			int oQuad = JArray_objectWithInts(quad)
			JIntMap_SetObj(optionsMap, quad[1], oQuad)
			JIntMap_SetObj(optionsMap, quad[2], oQuad)
			JIntMap_SetObj(optionsMap, quad[3], oQuad)
		endIf
		index += 1
	endWhile
EndFunction

state WeightAddFemaleMorphState
	event OnInputOpenST()
		SetInputDialogStartText("")
	endEvent

	event OnInputAcceptST(string a_input)
		Core.AddMorph(a_input, 0.0, 0.0, 0)
		ForcePageReset()
	endEvent

	event OnHighlightST()
		SetInfoText("Add a female weight morph.")
	endEvent
endState

state WeightAddMaleMorphState
	event OnInputOpenST()
		SetInputDialogStartText("")
	endEvent

	event OnInputAcceptST(string a_input)
		Core.AddMorph(a_input, 0.0, 0.0, 1)
		ForcePageReset()
	endEvent

	event OnHighlightST()
		SetInfoText("Add a male weight morph.")
	endEvent
endState

state WeightAddCreatureMorphState
	event OnInputOpenST()
		SetInputDialogStartText("")
	endEvent
	event OnInputAcceptST(string a_input)
		Core.AddMorph(a_input, 0.0, 0.0, 2)
		ForcePageReset()
	endEvent
	event OnHighlightST()
		SetInfoText("Add a creature weight morph.")
	endEvent
endState

state FemaleNormal0State
	event OnInputOpenST()
		SetInputDialogStartText(Core.FemaleNormals[0])
	endEvent

	event OnInputAcceptST(string a_input)
		Core.FemaleNormals[0] = a_input
		SetInputOptionValueST(Core.FemaleNormals[0])
		Core.NormalMapUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent

	event OnDefaultST()
		Core.FemaleNormals[0] = "Actors\\Character\\Female\\FemaleBody_1_msn.dds"
		SetInputOptionValueST(Core.FemaleNormals[0])
		Core.NormalMapUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent

	event OnHighlightST()
		SetInfoText("The default Normal Map that will be applied to Females when they drop below the thresholds for any higher Normals.")
	endEvent
endState

state FemaleNormal1State
	event OnInputOpenST()
		SetInputDialogStartText(Core.FemaleNormals[1])
	endEvent

	event OnInputAcceptST(string a_input)
		Core.FemaleNormals[1] = a_input
		SetInputOptionValueST(Core.FemaleNormals[1])
		Core.NormalMapUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent

	event OnDefaultST()
		Core.FemaleNormals[1] = "Actors\\Character\\Winterweight\\Female\\FemaleBody_chubby1_msn.dds"
		SetInputOptionValueST(Core.FemaleNormals[1])
		Core.NormalMapUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent

	event OnHighlightST()
		SetInfoText("The first Normal Map that will be applied to Females when they rise above the associated threshold.")
	endEvent
endState

state FemaleNormal2State
	event OnInputOpenST()
		SetInputDialogStartText(Core.FemaleNormals[2])
	endEvent

	event OnInputAcceptST(string a_input)
		Core.FemaleNormals[2] = a_input
		SetInputOptionValueST(Core.FemaleNormals[2])
		Core.NormalMapUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent

	event OnDefaultST()
		Core.FemaleNormals[2] = ""
		SetInputOptionValueST(Core.FemaleNormals[2])
		Core.NormalMapUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent

	event OnHighlightST()
		SetInfoText("The second Normal Map that will be applied to Females when they rise above the associated threshold.")
	endEvent
endState

state MaleNormal0State
	event OnInputOpenST()
		SetInputDialogStartText(Core.MaleNormals[0])
	endEvent

	event OnInputAcceptST(string a_input)
		Core.MaleNormals[0] = a_input
		SetInputOptionValueST(Core.MaleNormals[0])
		Core.NormalMapUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent

	event OnDefaultST()
		Core.MaleNormals[0] = "Actors\\Character\\Male\\MaleBody_1_msn.dds"
		SetInputOptionValueST(Core.MaleNormals[0])
		Core.NormalMapUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent

	event OnHighlightST()
		SetInfoText("The default Normal Map that will be applied to Males when they drop below the thresholds for any higher Normals.")
	endEvent
endState

state MaleNormal1State
	event OnInputOpenST()
		SetInputDialogStartText(Core.MaleNormals[1])
	endEvent

	event OnInputAcceptST(string a_input)
		Core.MaleNormals[1] = a_input
		SetInputOptionValueST(Core.MaleNormals[1])
		Core.NormalMapUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent

	event OnDefaultST()
		Core.MaleNormals[1] = ""
		SetInputOptionValueST(Core.MaleNormals[1])
		Core.NormalMapUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent

	event OnHighlightST()
		SetInfoText("The first Normal Map that will be applied to Males when they rise above the associated threshold.")
	endEvent
endState

state MaleNormal2State
	event OnInputOpenST()
		SetInputDialogStartText(Core.MaleNormals[2])
	endEvent

	event OnInputAcceptST(string a_input)
		Core.MaleNormals[2] = a_input
		SetInputOptionValueST(Core.MaleNormals[2])
		Core.NormalMapUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent

	event OnDefaultST()
		Core.MaleNormals[2] = ""
		SetInputOptionValueST(Core.MaleNormals[2])
		Core.NormalMapUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent

	event OnHighlightST()
		SetInfoText("The second Normal Map that will be applied to Males when they rise above the associated threshold.")
	endEvent
endState

state ModEnableState
	event OnSelectST()
		Core.ModEnabled = !Core.ModEnabled
		setToggleOptionValueST(Core.ModEnabled)
		Core.EventRegistration()
		;ForcePageReset()
	endEvent
	event OnDefaultST()
		Core.ModEnabled = true
		setToggleOptionValueST(Core.ModEnabled)
		;ForcePageReset()
	endEvent
	event OnHighlightST()
		;SetInfoText("")
	endEvent
endstate

state PlayerEnabledState
	event OnSelectST()
		Core.PlayerEnabled = !Core.PlayerEnabled
		setToggleOptionValueST(Core.PlayerEnabled)
		;ForcePageReset()
	endEvent
	event OnDefaultST()
		Core.PlayerEnabled = true
		setToggleOptionValueST(Core.PlayerEnabled)
		;ForcePageReset()
	endEvent
	event OnHighlightST()
		;SetInfoText("")
	endEvent
endstate

state NPCsEnabledState
	event OnSelectST()
		Core.NPCsEnabled = !Core.NPCsEnabled
		setToggleOptionValueST(Core.NPCsEnabled)
		;ForcePageReset()
	endEvent
	event OnDefaultST()
		Core.NPCsEnabled = true
		setToggleOptionValueST(Core.NPCsEnabled)
		;ForcePageReset()
	endEvent
	event OnHighlightST()
		;SetInfoText("")
	endEvent
endstate

state ArmNodeEnabledState
	event OnSelectST()
		Core.ArmNodeChanges = !Core.ArmNodeChanges
		setToggleOptionValueST(Core.ArmNodeChanges)
		Core.ArmNodeUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent
	event OnDefaultST()
		Core.ArmNodeChanges = true
		setToggleOptionValueST(Core.ArmNodeChanges)
	endEvent
	event OnHighlightST()
		SetInfoText("If enabled, humans gaining weight will have their arms proportionally spread out in order to prevent clipping. The players' arms will update immediately on setting change.")
	endEvent
endstate

state ThighNodeEnabledState
	event OnSelectST()
		Core.ThighNodeChanges = !Core.ThighNodeChanges
		setToggleOptionValueST(Core.ThighNodeChanges)
		Core.ThighNodeUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent
	event OnDefaultST()
		Core.ThighNodeChanges = true
		setToggleOptionValueST(Core.ThighNodeChanges)
	endEvent
	event OnHighlightST()
		SetInfoText("If enabled, humans gaining weight will have their thighs proportionally spread out in order to prevent clipping. The players' thighs will update immediately on setting change.")
	endEvent
endstate

state DropFeedState
	event OnSelectST()
		If Core.DropFeeding.GetValue() == 0.0
			Core.DropFeeding.SetValue(1.0)
		Else
			Core.DropFeeding.SetValue(0.0)
		EndIf
		setToggleOptionValueST(Core.DropFeeding.GetValue() as Bool)
	endEvent
	event OnDefaultST()
		Core.DropFeeding.SetValue(0.0)
		setToggleOptionValueST(Core.DropFeeding.GetValue() as Bool)
	endEvent
	event OnHighlightST()
		SetInfoText("If enabled, your closest companion will pick up and eat any food items you drop.")
	endEvent
endstate

state FemaleNormalsEnabledState
	event OnSelectST()
		Core.FemaleNormalChanges = !Core.FemaleNormalChanges
		setToggleOptionValueST(Core.FemaleNormalChanges)
		Core.NormalMapUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent
	event OnDefaultST()
		Core.FemaleNormalChanges = true
		setToggleOptionValueST(Core.FemaleNormalChanges)
	endEvent
	event OnHighlightST()
		SetInfoText("If enabled, Female humans gaining weight will have extra belly roll and skin detail proportional to their weight.")
	endEvent
endstate

state MaleNormalsEnabledState
	event OnSelectST()
		Core.MaleNormalChanges = !Core.MaleNormalChanges
		setToggleOptionValueST(Core.MaleNormalChanges)
		Core.NormalMapUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent
	event OnDefaultST()
		Core.MaleNormalChanges = true
		setToggleOptionValueST(Core.MaleNormalChanges)
	endEvent
	event OnHighlightST()
		SetInfoText("If enabled, Male humans gaining weight will have extra belly roll and skin detail proportional to their weight.")
	endEvent
endstate

state ShowHighValueState
	event OnSelectST()
		ValueOptions = 0
		Debug.MessageBox("On closing the menu, the High Value food configuration menu will be shown.")
	endEvent
	event OnHighlightST()
		SetInfoText("Clicking this will open the High Value Menu. High Value foods are worth double the ordinary amount of weight gain, so eating them provides DOUBLE their weight * base food gain.")
	endEvent
endstate

state ShowNoValueState
	event OnSelectST()
		ValueOptions = 1
		Debug.MessageBox("On closing the menu, the No Value food configuration menu will be shown.")
	endEvent
	event OnHighlightST()
		SetInfoText("Clicking this will open the No Value Menu. No Value foods are worth no weight gain. Use this list for items like Water.")
	endEvent
endstate

state SaveSettingsState
	event OnSelectST()
		If Core.SaveSettings()
			Debug.MessageBox("Saved Winterweight Settings.")
		EndIf
		;ForcePageReset()
	endEvent
endstate

state LoadSettingsState
	event OnSelectST()
		If Core.LoadSettings()
			Debug.MessageBox("Loaded Winterweight Settings.")
		EndIf
		;ForcePageReset()
	endEvent
endstate

state ResetOneState
	event OnSelectST()
		Core.ResetActorWeight(target)
		Debug.MessageBox("Resetting " +Namer(target, true)+ "'s Weight on menu close.")
	endEvent
endstate

state ResetAllState
	event OnSelectST()
		Core.ResetActorWeights()
		Debug.MessageBox("Resetting ALL Actor Weights on menu close.")
	endEvent
endstate

state MaximumWeightState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Core.MaximumWeight)
		SetSliderDialogDefaultValue(2.0)
		SetSliderDialogRange(Core.MinimumWeight, 20.0)
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(float a_value)
		Core.MaximumWeight = a_value
		SetSliderOptionValueST(a_value, "{2}")
	endEvent

	event OnDefaultST()
		SetSliderOptionValueST(Core.MaximumWeight, "{2}")
	endEvent

	event OnHighlightST()
		;SetInfoText("")
	endEvent
endState

state MinimumWeightState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Core.MinimumWeight)
		SetSliderDialogDefaultValue(-1.0)
		SetSliderDialogRange(-4.0, Core.MaximumWeight)
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(float a_value)
		Core.MinimumWeight = a_value
		SetSliderOptionValueST(a_value, "{2}")
	endEvent

	event OnDefaultST()
		SetSliderOptionValueST(Core.MinimumWeight, "{2}")
	endEvent

	event OnHighlightST()
		;SetInfoText("The minimum Weight can be.")
	endEvent
endState

state ArmNodeFactorState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Core.ArmNodeFactor)
		SetSliderDialogDefaultValue(4.0)
		SetSliderDialogRange(0.01, 10.0)
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(float a_value)
		Core.ArmNodeFactor = a_value
		SetSliderOptionValueST(a_value, "{2}")
		Core.ArmNodeUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent

	event OnDefaultST()
		SetSliderOptionValueST(Core.ArmNodeFactor, "{2}")
	endEvent

	event OnHighlightST()
		SetInfoText("The amount in degrees that the shoulder and clavicle bones will be adjusted by at Maximum Weight. Higher factors may cause strange warping. The players' arms will update immediately on setting change.")
	endEvent
endState

state ThighNodeFactorState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Core.ThighNodeFactor)
		SetSliderDialogDefaultValue(4.0)
		SetSliderDialogRange(0.01, 10.0)
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(float a_value)
		Core.ThighNodeFactor = a_value
		SetSliderOptionValueST(a_value, "{2}")
		Core.ThighNodeUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent

	event OnDefaultST()
		SetSliderOptionValueST(Core.ThighNodeFactor, "{2}")
	endEvent

	event OnHighlightST()
		SetInfoText("The amount in degrees that the hip bones will be adjusted by at Maximum Weight. Higher factors may cause strange warping. The players' arms will update immediately on setting change.")
	endEvent
endState

state FemaleNormal1ThresholdState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Core.FemaleNormalBreakpoints[1])
		SetSliderDialogDefaultValue(1.0)
		Float EndPoint = Core.MaximumWeight
		If Core.FemaleNormalBreakpoints[2] != 0.0
			EndPoint = Core.FemaleNormalBreakpoints[2] - 0.01
		EndIf
		SetSliderDialogRange(0.01, EndPoint)
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(float a_value)
		Core.FemaleNormalBreakpoints[1] = a_value
		SetSliderOptionValueST(a_value, "{2} Weight")
		Core.NormalMapUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent

	event OnDefaultST()
		SetSliderOptionValueST(Core.FemaleNormalBreakpoints[1], "{2} Weight")
	endEvent

	event OnHighlightST()
		SetInfoText("The Weight above which this Normal Map will be applied.")
	endEvent
endState

state FemaleNormal2ThresholdState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Core.FemaleNormalBreakpoints[2])
		SetSliderDialogDefaultValue(1.5)
		SetSliderDialogRange(Core.FemaleNormalBreakpoints[1], Core.MaximumWeight)
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(float a_value)
		Core.FemaleNormalBreakpoints[2] = a_value
		SetSliderOptionValueST(a_value, "{2} Weight")
		Core.NormalMapUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent

	event OnDefaultST()
		SetSliderOptionValueST(Core.FemaleNormalBreakpoints[2], "{2} Weight")
	endEvent

	event OnHighlightST()
		SetInfoText("The Weight above which this Normal Map will be applied.")
	endEvent
endState

state MaleNormal1ThresholdState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Core.MaleNormalBreakpoints[1])
		SetSliderDialogDefaultValue(1.0)
		Float EndPoint = Core.MaximumWeight
		If Core.MaleNormalBreakpoints[2] != 0.0
			EndPoint = Core.MaleNormalBreakpoints[2] - 0.01
		EndIf
		SetSliderDialogRange(0.01, EndPoint)
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(float a_value)
		Core.MaleNormalBreakpoints[1] = a_value
		SetSliderOptionValueST(a_value, "{2} Weight")
		Core.NormalMapUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent

	event OnDefaultST()
		SetSliderOptionValueST(Core.MaleNormalBreakpoints[1], "{2} Weight")
	endEvent

	event OnHighlightST()
		SetInfoText("The Weight above which this Normal Map will be applied.")
	endEvent
endState

state MaleNormal2ThresholdState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Core.MaleNormalBreakpoints[2])
		SetSliderDialogDefaultValue(1.5)
		SetSliderDialogRange(Core.MaleNormalBreakpoints[1], Core.MaximumWeight)
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(float a_value)
		Core.MaleNormalBreakpoints[2] = a_value
		SetSliderOptionValueST(a_value, "{2} Weight")
		Core.NormalMapUpdate(PlayerRef, StorageUtil.GetFloatValue(PlayerRef, MODKEY, 0.0))
	endEvent

	event OnDefaultST()
		SetSliderOptionValueST(Core.MaleNormalBreakpoints[2], "{2} Weight")
	endEvent

	event OnHighlightST()
		SetInfoText("The Weight above which this Normal Map will be applied.")
	endEvent
endState

state WeightLossState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Core.WeightLoss)
		SetSliderDialogDefaultValue(0.03)
		SetSliderDialogRange(0.01, 1.0)
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(float a_value)
		Core.WeightLoss = a_value
		SetSliderOptionValueST(a_value, "{2}")
	endEvent

	event OnDefaultST()
		SetSliderOptionValueST(Core.WeightLoss, "{2}")
	endEvent

	event OnHighlightST()
		SetInfoText("The amount of weight NPCs lose each time Weight Loss runs.")
	endEvent
endState

state WeightRateState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Core.WeightRate)
		SetSliderDialogDefaultValue(0.25)
		SetSliderDialogRange(0.01, 24.0)
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(float a_value)
		Core.WeightRate = a_value
		SetSliderOptionValueST(a_value, "{2}")
	endEvent

	event OnDefaultST()
		SetSliderOptionValueST(Core.WeightRate, "{2}")
	endEvent

	event OnHighlightST()
		SetInfoText("How often Weight Loss runs.")
	endEvent
endState

state WeightLossEnabledState
	event OnSelectST()
		Core.WeightLossEnabled = !Core.WeightLossEnabled
		setToggleOptionValueST(Core.WeightLossEnabled)
		Core.EventRegistration()
		;ForcePageReset()
	endEvent
	event OnDefaultST()
		Core.WeightLossEnabled = true
		setToggleOptionValueST(Core.WeightLossEnabled)
		;ForcePageReset()
	endEvent
	event OnHighlightST()
		;SetInfoText("")
	endEvent
endstate

state IngredientGainState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Core.IngredientBaseGain)
		SetSliderDialogDefaultValue(0.04)
		SetSliderDialogRange(0.001, 5.0)
		SetSliderDialogInterval(0.001)
	endEvent

	event OnSliderAcceptST(float a_value)
		Core.IngredientBaseGain = a_value
		SetSliderOptionValueST(a_value, "{3} * Item Weight")
	endEvent

	event OnDefaultST()
		SetSliderOptionValueST(Core.IngredientBaseGain, "{3} * Item Weight")
	endEvent

	event OnHighlightST()
		SetInfoText("How much weight Ingredients give. Is multiplied by Ingredient weight, so an ingredient weighing 0.5 with a Base Gain of 0.04 would give 0.02 weight.")
	endEvent
endState

state PotionGainState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Core.PotionBaseGain)
		SetSliderDialogDefaultValue(0.02)
		SetSliderDialogRange(0.001, 5.0)
		SetSliderDialogInterval(0.001)
	endEvent

	event OnSliderAcceptST(float a_value)
		Core.PotionBaseGain = a_value
		SetSliderOptionValueST(a_value, "{3} * Item Weight")
	endEvent

	event OnDefaultST()
		SetSliderOptionValueST(Core.PotionBaseGain, "{3} * Item Weight")
	endEvent

	event OnHighlightST()
		SetInfoText("How much weight Potions give. Is multiplied by Potion weight, so a potion weighing 0.5 with a Base Gain of 0.02 would give 0.01 weight. /n I prefer to keep this low since all vanilla potions weigh 0.5 anyways.")
	endEvent
endState

state FoodGainState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Core.FoodBaseGain)
		SetSliderDialogDefaultValue(0.10)
		SetSliderDialogRange(0.001, 5.0)
		SetSliderDialogInterval(0.001)
	endEvent

	event OnSliderAcceptST(float a_value)
		Core.FoodBaseGain = a_value
		SetSliderOptionValueST(a_value, "{3} * Item Weight")
	endEvent

	event OnDefaultST()
		SetSliderOptionValueST(Core.FoodBaseGain, "{3} * Item Weight")
	endEvent

	event OnHighlightST()
		SetInfoText("How much weight food items give. Is multiplied by item weight, so food weighing 0.5 with a Base Gain of 0.10 would give 0.05 weight. /n Foods that are marked as High Value are worth double, and foods marked as No Value give no weight gain.")
	endEvent
endState

state VoreGainState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Core.VoreBaseGain)
		SetSliderDialogDefaultValue(0.03)
		SetSliderDialogRange(0.001, 5.0)
		SetSliderDialogInterval(0.001)
	endEvent

	event OnSliderAcceptST(float a_value)
		Core.VoreBaseGain = a_value
		SetSliderOptionValueST(a_value, "{3} / Stage")
	endEvent

	event OnDefaultST()
		SetSliderOptionValueST(Core.VoreBaseGain, "{3} / Stage")
	endEvent

	event OnHighlightST()
		SetInfoText("How much weight you gain per step of digesting prey. This can occur many times, depending on how large the prey is.")
	endEvent
endState

state PreviewState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(0.0)
		SetSliderDialogDefaultValue(0.0)
		SetSliderDialogRange(-4.0, 20.0)
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(float a_value)
		SetSliderOptionValueST(a_value, "{2}")
		Core.BodyMorphUpdate(Target, a_value)
		Core.ArmNodeUpdate(Target, a_value)
		Core.ThighNodeUpdate(Target, a_value)
		Core.NormalMapUpdate(Target, a_value)
		RegisterForSingleUpdate(10.0)
	endEvent

	event OnDefaultST()
		SetSliderOptionValueST(0.0, "{2}")
	endEvent

	event OnHighlightST()
		SetInfoText("Previews what the target will look like at a given weight, based on your current settings. If you're not looking at an NPC, the player will be the target. Previewing will end after ten seconds.")
	endEvent
endState

state SetWeightState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(0.0)
		SetSliderDialogDefaultValue(0.0)
		SetSliderDialogRange(-4.0, 20.0)
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(float a_value)
		SetSliderOptionValueST(a_value, "{2}")
		Float fWeight = StorageUtil.SetFloatValue(Target, MODKEY, a_value)
		Core.BodyMorphUpdate(Target, fWeight)
		Core.ArmNodeUpdate(Target, fWeight)
		Core.ThighNodeUpdate(Target, fWeight)
		Core.NormalMapUpdate(Target, fWeight)
	endEvent

	event OnDefaultST()
		SetSliderOptionValueST(0.0, "{2}")
	endEvent

	event OnHighlightST()
		SetInfoText("Sets the targets weight. Note, this is not like previews, this sets the targets *real* winterweight weight value.")
	endEvent
endState

Event OnUpdate()
	Float fOldWeight = Core.GetCurrentActorWeight(Target)
	Core.BodyMorphUpdate(Target, fOldWeight)
	Core.ArmNodeUpdate(Target, fOldWeight)
	Core.ThighNodeUpdate(Target, fOldWeight)
	Core.NormalMapUpdate(Target, fOldWeight)
EndEvent

event OnOptionInputOpen(int oid)

	if !AssertTrue(PREFIX, "OnOptionInputOpen", "JIntMap_HasKey(optionsMap, oid)", JIntMap_HasKey(optionsMap, oid))
		return
	endIf

	String[] MorphStrings = Core.MorphStrings
	float[] MultLow = Core.MorphsLow
	float[] MultHigh = Core.MorphsHigh

	; Get the quad.
	int oq = JIntMap_GetObj(optionsMap, oid)
	if !AssertExists(PREFIX, "OnOptionInputOpen", "oq", oq)
		return
	endIf

	int[] quad = JArray_asIntArray(oq)
	int index = quad[0]
	String morph = MorphStrings[index]

	if oid == quad[1]
		SetInputDialogStartText(MorphStrings[index])
	elseif oid == quad[2]
		SetInputDialogStartText(MultLow[index])
	elseif oid == quad[3]
		SetInputDialogStartText(MultHigh[index])
	endIf
endEvent

event OnOptionInputAccept(int oid, string a_input)
	
	if !AssertTrue(PREFIX, "OnOptionInputAccept", "JIntMap_hasKey(optionsMap, oid)", JIntMap_hasKey(optionsMap, oid))
		return
	endIf
	
	String[] MorphStrings = Core.MorphStrings
	float[] MultLow = Core.MorphsLow
	float[] MultHigh = Core.MorphsHigh
	
	; Get the quad.
	int oq = JIntMap_GetObj(optionsMap, oid)
	if !AssertExists(PREFIX, "OnOptionInputAccept", "oq", oq)
		return
	endIf
	
	int[] quad = JArray_asIntArray(oq)
	int index = quad[0]
	String morph = MorphStrings[index]
	
	if oid == quad[1]
		if a_input == ""
			Core.RemoveMorph(index)
			ForcePageReset()
		else
			MorphStrings[index] = a_input
			SetInputOptionValue(oid, a_input)
		endIf
	
	elseif oid == quad[2]
		float val = a_input as float
		MultLow[index] = val
		SetInputOptionValue(oid, val)
		
	elseif oid == quad[3]
		float val = a_input as float
		MultHigh[index] = val
		SetInputOptionValue(oid, val)
	endIf
endEvent

Function ActorWeightLoss(ObjectReference akTarget)	;A strange NiOverride workaround, as Ref Alias' are not Form inheritor.
	Core.ActorWeightLoss(akTarget as Actor)
EndFunction

Function ResetActorWeights(ObjectReference akTarget)
	Core.ResetActorWeight(akTarget as Actor)
EndFunction