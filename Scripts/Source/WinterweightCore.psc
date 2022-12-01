ScriptName WinterweightCore Extends ReferenceAlias
{
AUTHOR: Gaz
PURPOSE: WeightMorphs-esque Weight Gain/Loss Manager for both Player and NPCs.
CREDIT: Ousnius, MarkDF, and CreationClub Survival Mode for providing the basis for this implementation.
}

import Winterweight_JCDomain
Import Logging

Actor Property PlayerRef Auto
Armor Property HandsArmor Auto
WinterweightMCM Property WinterMCM Auto
String[] Property MorphStrings auto
Float[] Property MorphsHigh auto
Float[] Property MorphsLow auto
GlobalVariable Property GameDaysPassed Auto	;Vanilla global.
GlobalVariable Property DropFeeding Auto

Form[] Property HighValueFood Auto
Form[] Property NoValueFood Auto
Keyword Property ActorTypeCreature Auto

;Message property MenuWhitelist auto
;ReferenceAlias property WhitelistNameAlias auto
Bool Property ModEnabled = True Auto
Bool Property PlayerEnabled = True Auto Hidden
Bool Property NPCsEnabled = True Auto Hidden
Bool Property ArmNodeChanges = True Auto Hidden
Bool Property ThighNodeChanges = True Auto Hidden
Bool Property FemaleNormalChanges = True Auto Hidden
Bool Property MaleNormalChanges = True Auto Hidden
Bool Property WeightLossEnabled = True Auto Hidden
Float[] Property FemaleNormalBreakpoints Auto Hidden
Float[] Property MaleNormalBreakpoints Auto Hidden
Float Property WeightLoss = 0.03 Auto Hidden
Float Property WeightRate = 0.25 Auto Hidden
{How often we run WeightLoss.}
Float Property MaximumWeight = 2.0 Auto Hidden
Float Property MinimumWeight = -1.0 Auto Hidden
Float Property ArmNodeFactor = 4.0 Auto Hidden
Float Property ThighNodeFactor = 4.0 Auto Hidden
Float Property IngredientBaseGain = 0.04 Auto Hidden
Float Property PotionBaseGain = 0.02 Auto Hidden
Float Property FoodBaseGain = 0.10 Auto Hidden
Float Property VoreBaseGain = 0.03 Auto Hidden
Float Property HighValueMultiplier = 2.0 Auto Hidden
TextureSet Property WinterweightSkinBodyFemale Auto
Quest Property RefactorManager = None Auto Hidden
;Actor[] property WeightWhitelist auto

String[] Property FemaleNormals Auto Hidden
String[] Property MaleNormals Auto Hidden
String Property SettingsFileName = "data\\skse\\plugins\\winterweight\\settings.json" autoreadonly Hidden

String MODKEY = "Winterweight.esp"
String PREFIX = "WinterweightCore"

;Bool DetectedSleepEvent = False

;Float SleepStartHour = 0.0
;Float SleepEndHour = 0.0
Bool UpdateMutex = False
Float LastGameHours = 0.0
Int Ticks = 0	;Holding variable for Ticks since last processed while we're doing WeightLoss.

Event OnInit()
	;EventRegistration()
	FemaleNormals = New String[3]
	FemaleNormals[0] = "Actors\\Character\\Female\\FemaleBody_1_msn.dds"
	FemaleNormals[1] = "Actors\\Character\\Winterweight\\Female\\FemaleBody_chubby1_msn.dds"
	FemaleNormalBreakpoints = New Float[3]
	FemaleNormalBreakpoints[1] = 1.0
	FemaleNormalBreakpoints[2] = 1.5

	MaleNormals = New String[3]
	MaleNormals[0] = "Actors\\Character\\Male\\MaleBody_1_msn.dds"
	MaleNormalBreakpoints = New Float[3]
	MaleNormalBreakpoints[1] = 1.0
	MaleNormalBreakpoints[2] = 1.5

	if MorphStrings.length < 96 || MorphsHigh.length < 96 || MorphsLow.length < 96
        MorphStrings = Utility.ResizeStringArray(MorphStrings, 96)
        MorphsHigh = Utility.ResizeFloatArray(MorphsHigh, 96)
        MorphsLow = Utility.ResizeFloatArray(MorphsLow, 96)
    endIf
	
	RegisterForModEvent("Winterweight_ItemConsume", "ItemConsume")
	CheckRefactor()	;Checks for Devourment Refactor.
	RunPatchups()
EndEvent

Event OnPlayerLoadGame()
	RegisterForModEvent("Winterweight_ItemConsume", "ItemConsume")
	EventRegistration()
	CheckRefactor()
EndEvent

Function CheckRefactor()
	RefactorManager = Quest.GetQuest("DevourmentManager")
EndFunction

Function EventRegistration()
	RunPatchups()
    If ModEnabled
		If WeightLossEnabled
			;RegisterForSleep()	;Our logic being, time passing only really matters if weightloss is a thing.
			;RegisterForModEvent("HookAnimationEnd", "SexlabAnimationEnd")
			LastGameHours = GameDaysPassed.GetValue() * 24
			RegisterForSingleUpdateGameTime(WeightRate)
		EndIf
    Else 
		;UnregisterForModEvent("HookAnimationEnd")
		UnregisterForUpdateGameTime()
		;UnregisterForSleep()
    EndIf
EndFunction

Int Function GetTicks(Float currentTimeInGameHours, Float lastTimeInGameHours)	;This function shamelessly ripped off from CreationClub SurvivalMode Survival_NeedBase.
	Int returnticks = (currentTimeInGameHours - lastTimeInGameHours) as Int * (1.0 / WeightRate) as Int
	if returnticks < 0
		returnticks = 0
	endIf
	Log4(PREFIX, "GetTicks()", "currentTime: " +currentTimeInGameHours, "lastTime: " +lastTimeInGameHours, "weightRate: " +WeightRate, "ticks: " +returnticks)
	return returnticks
endFunction

Event OnUpdateGameTime()
	If ModEnabled
		If WeightLossEnabled
			self.NeedUpdateGameTime()
			Log1(PREFIX, "OnUpdateGameTime()", "Update at: " +GameDaysPassed.GetValue() * 24)
			RegisterForSingleUpdateGameTime(WeightRate)
		EndIf
	EndIf
EndEvent 

function NeedUpdateGameTime()
	Float currentTimeInGameHours = GameDaysPassed.GetValue() * 24
	If LastGameHours == 0.0
		LastGameHours = currentTimeInGameHours
		Log1(PREFIX, "NeedUpdateGameTime()", "First update, weight loss skipped.")
	Else
		Ticks = self.GetTicks(currentTimeInGameHours, LastGameHours)
		Log3(PREFIX, "NeedUpdateGameTime()", "Processing weight loss. Ticks: " +Ticks, " CurrentTimeInGameHours: " +currentTimeInGameHours, "LastGameHours: " +LastGameHours)
		LastGameHours = currentTimeInGameHours
		NiOverride.ForEachMorphedReference("ActorWeightLoss", WinterMCM)
		;Ticks = 0
	EndIf
endFunction

Function ActorWeightLoss(Actor akTarget)
	ChangeActorWeight(akTarget, (WeightLoss * -1) * (Ticks as Float))
	Log2(PREFIX, "ActorWeightLoss()", "Actor: " +akTarget.GetDisplayName(), "WeightLoss: " +(WeightLoss * -1) * (Ticks as Float))
EndFunction

;/
Event OnSleepStart(float afSleepStartTime, float afDesiredSleepEndTime)
	SleepStartHour = GameDaysPassed.GetValue() * 24
EndEvent

Event OnSleepStop(bool abInterrupted)
	SleepEndHour = GameDaysPassed.GetValue() * 24
EndEvent
/;

;/
Event SexlabAnimationEnd(int tid, bool HasPlayer)
	if HasPlayer
		;ChangeActorWeight(PlayerRef, -WeightLoss, source="orgasm")
	endIf
EndEvent
/;

Event ItemConsume(Form consumer, Form itemBase, int count)
{ Event that fires when Actors consume something via Feeding. Also called for Player Equip events. }

	If ModEnabled
		If NoValueFood.Find(itemBase) >= 0
			ConsoleUtil.PrintMessage(Namer(itemBase) + " has no food value.")
			Return
		endIf
		
		Actor gainer = consumer as Actor
		If gainer == PlayerRef && !PlayerEnabled
			Return
		ElseIf gainer != PlayerRef && !NPCsEnabled
			Return
		EndIf
		;/
		If WeightWhitelist.find(gainer) < 0 
		;	Log1(PREFIX, "ItemConsume()", "INVALID CONSUMER")
			return
		endIf
		/;
		if count <= 0
			count = 1
		endif
		float baseWeight = itemBase.GetWeight() * count
		if itembase.GetWeight() == 0.0	;Failover procedure for objects in Quest Object Alias' or otherwise with weight nullification.
			baseWeight = ((itembase as ObjectReference).GetBaseObject().GetWeight()) * count
		endIf
		
		If FoodBaseGain > 0.0 && itemBase.HasKeywordString("VendorItemFood")
			
			If HighValueFood.Find(itemBase) >= 0
				ConsoleUtil.PrintMessage("Got high value food equip event. " +Namer(itemBase))
				ChangeActorWeight(gainer, (FoodBaseGain * baseWeight) * HighValueMultiplier)
			else
				ConsoleUtil.PrintMessage("Got food equip event worth: " +(FoodBaseGain * baseWeight)+ " " +Namer(itemBase))
				ChangeActorWeight(gainer, (FoodBaseGain * baseWeight))
			EndIf
			;Manager.RegisterFakeDigestion(gainer, baseWeight * 2.0)

		ElseIf PotionBaseGain > 0.0 && itemBase.HasKeywordString("VendorItemPotion")
			ConsoleUtil.PrintMessage("Got potion equip event. " +itemBase)
			ChangeActorWeight(gainer, PotionBaseGain)
			;Manager.RegisterFakeDigestion(gainer, baseWeight)
			
		ElseIf IngredientBaseGain > 0.0 && itemBase as Ingredient
			ConsoleUtil.PrintMessage("Got ingredient equip event. " +itemBase)
			ChangeActorWeight(gainer, IngredientBaseGain * baseWeight)
			;Manager.RegisterFakeDigestion(gainer, baseWeight)
		EndIf
	EndIf
EndEvent

Event OnObjectEquipped(Form type, ObjectReference ref)
	if PlayerEnabled
		if type as Potion || type as Ingredient
			ItemConsume(PlayerRef, type, 1)
		endIf
	endIf
EndEvent

auto state DefaultState
endState

Function LearnValue(int Type)
	if Type == 0
		GoToState("LearnHighValue")
	else
		GoToState("LearnNoValue")
	endif
EndFunction

state LearnNoValue
	Event OnObjectEquipped(Form type, ObjectReference ref)
		if type as Potion || type as Ingredient
			addNoValueFood(type)
			ConsoleUtil.PrintMessage("Added No-Value food: " + Namer(type))
		endIf
	EndEvent
endState

state LearnHighValue
	Event OnObjectEquipped(Form type, ObjectReference ref)
		if type as Potion || type as Ingredient
			addHighValueFood(type)
			ConsoleUtil.PrintMessage("Added High-Value food: " + Namer(type))
		endIf
	EndEvent
endState

Function ResetActorWeight(Actor target)
	if target
		;/
		NIOverride.RemoveNodeTransformScale(target, false, isFemale, rootNode, PREFIX)
		NIOverride.UpdateNodeTransform(target, false, isFemale, rootNode)
		/;

		if NiOverride.HasBodyMorphKey(target, MODKEY)
			NiOverride.ClearBodyMorphKeys(target, MODKEY)
			NiOverride.ClearBodyMorphKeys(target, MODKEY)	;Call twice, since sometimes this one seems to fail on first call.
			NiOverride.UpdateModelWeight(target)
		endIf

		bool isFemale = IsFemale(target)
		NiOverride.RemoveNodeTransformRotation(target, false, isFemale, "CME R Hip", MODKEY)
		NiOverride.RemoveNodeTransformRotation(target, false, isFemale, "CME L Hip", MODKEY)
		NiOverride.RemoveNodeTransformRotation(target, false, isFemale, "CME R Clavicle [RClv]", MODKEY)
		NiOverride.RemoveNodeTransformRotation(target, false, isFemale, "CME L Clavicle [LClv]", MODKEY)
		NiOverride.RemoveNodeTransformRotation(target, false, isFemale, "CME R Shoulder", MODKEY)
		NiOverride.RemoveNodeTransformRotation(target, false, isFemale, "CME L Shoulder", MODKEY)
		NiOverride.RemoveSkinOverride(target, IsFemale, false, 0x04, 9, 1)
		StorageUtil.UnSetFloatValue(target, MODKEY)
	endIf
EndFunction

Function ResetActorWeights()
	NiOverride.ForEachMorphedReference("ResetActorWeight", WinterMCM)
EndFunction

float Function GetCurrentActorWeight(Actor target)
	return StorageUtil.GetFloatValue(target, MODKEY, 0.0)
EndFunction

float Function GetCurrentActorWeightPercent(Actor target)
	;if isValidConsumer(target)
		return 0.3333 + 2.0*(GetCurrentActorWeight(target) - MinimumWeight) / (MaximumWeight - MinimumWeight)
	;else
	;	return 1.0
	;endIf
EndFunction

bool Function IsFemale(Actor target)
	return target.getLeveledActorBase().getSex()
EndFunction

Bool Function ChangeActorWeight(Actor target, float afChange, float afSplitThreshold = 0.05)
{ All-purpose function for losing and gaining Weight. }

	If !ModEnabled
		Return False
	ElseIf target == PlayerRef && (PlayerEnabled == False)
		Return False
	ElseIf target != PlayerRef && (NPCsEnabled == False)
		Return False
	EndIf
	
	int iAdds = Math.Ceiling(afChange / afSplitThreshold)
	if iAdds == 0
		iAdds = 1
	endIf
	Float fRaw = afChange / iAdds
	If StorageUtil.FloatListAdd(target, MODKEY, fRaw)
		iAdds -= 1
		While iAdds > 0
			StorageUtil.FloatListAdd(target, MODKEY, fRaw)
			iAdds -= 1
		EndWhile
		StorageUtil.FormListAdd(None, MODKEY, target)
		ConsoleUtil.PrintMessage("Actor " + Namer(target, true) + " changed weight by " + afChange + ".")
		If !UpdateMutex
			FullActorUpdate()
		EndIf
		Return True
	EndIf

	Return False
EndFunction

Function FullActorUpdate()

	If UpdateMutex
		Return
	EndIf
	UpdateMutex = True

	ConsoleUtil.PrintMessage("Full Actor Update Procedure called.")
	Form NextGainer = StorageUtil.FormListShift(None, MODKEY)
	While NextGainer
		Float Current = StorageUtil.GetFloatValue(NextGainer, MODKEY, 0.0)
		Actor Target = NextGainer as Actor
		While StorageUtil.FloatListCount(NextGainer, MODKEY) > 0
			Float Delta = StorageUtil.FloatListShift(NextGainer, MODKEY)
			Current = PapyrusUtil.ClampFloat(Current + Delta, MinimumWeight, MaximumWeight)
			BodyMorphUpdate(Target, Current)
			ArmNodeUpdate(Target, Current)
			ThighNodeUpdate(Target, Current)
			NormalMapUpdate(Target, Current)
		EndWhile
		StorageUtil.SetFloatValue(NextGainer, MODKEY, Current)
		NextGainer = StorageUtil.FormListShift(None, MODKEY)
	EndWhile

	UpdateMutex = False

EndFunction

Function BodyMorphUpdate(Actor akTarget, Float afWeight)

	int endPoint = 32
	int iSlider = 0
	bool isFemale = IsFemale(akTarget)

	If !akTarget.HasKeyword(ActorTypeCreature)
		If !isFemale
			iSlider = 32
			endPoint = 64
		EndIf
	Else
		iSlider = 64
		endPoint = 96
	EndIf

	if afWeight < 0.0	;Targets need to be inverted for the sliders to end up at correct values if target is below 0.0 weight.
		While iSlider < endPoint && MorphStrings[iSlider] != ""
			NiOverride.SetBodyMorph(akTarget, MorphStrings[iSlider], MODKEY, -afWeight * MorphsLow[iSlider])
			iSlider += 1
		EndWhile
	else
		While iSlider < endPoint && MorphStrings[iSlider] != ""
			NiOverride.SetBodyMorph(akTarget, MorphStrings[iSlider], MODKEY, afWeight * MorphsHigh[iSlider])
			iSlider += 1
		EndWhile
	endIf
	NiOverride.UpdateModelWeight(akTarget) ; Update the model.

EndFunction

Function NormalMapUpdate(Actor akTarget, Float afWeight)

	If akTarget.HasKeywordString("ActorTypeNPC") && (FemaleNormalChanges || MaleNormalChanges)

		String StartingTex = NiOverride.GetSkinOverrideString(akTarget, IsFemale, false, 0x04, 9, 1)
		String FetchedTex
		bool isFemale = IsFemale(akTarget)
		If isFemale && FemaleNormalChanges
			int iIndex = FemaleNormals.Length - 1
			While iIndex > -1
				If afWeight >= FemaleNormalBreakpoints[iIndex] && FemaleNormals[iIndex] != "" && StartingTex != FemaleNormals[iIndex]
					FetchedTex = FemaleNormals[iIndex]
					Armor Hands = akTarget.GetWornForm(0x08) as Armor
					If !Hands
						akTarget.EquipItem(HandsArmor, false, true)
					EndIf
					NiOverride.AddSkinOverrideString(akTarget, IsFemale, false, 0x04, 9, 1, FemaleNormals[iIndex], True)
					;NiOverride.AddSkinOverrideString(akTarget, IsFemale, false, 0x08, 9, 1, "Textures\\Actors\\Character\\Female\\FemaleHands_1_msn.dds", True)
					;NiOverride.AddSkinOverrideString(akTarget, IsFemale, false, 0x04, 9, 1, "Textures\\"+FemaleNormals[iIndex], True)
					;NiOverride.AddNodeOverrideTextureSet(akTarget, IsFemale, "3BAv2", 9, 1, WinterweightSkinBodyFemale, True)
					;NiOverride.AddNodeOverrideString(akTarget, IsFemale, "3BAv2", 9, 1, FemaleNormals[iIndex], False)
					;NiOverride.ApplyNodeOverrides(akTarget)
					iIndex = -1
				EndIf
				iIndex -= 1
			EndWhile
		ElseIf !isFemale && MaleNormalChanges
			int iIndex = MaleNormals.Length - 1
			While iIndex > -1
				If afWeight >= MaleNormalBreakpoints[iIndex] && MaleNormals[iIndex] != "" && StartingTex != MaleNormals[iIndex]
					FetchedTex = MaleNormals[iIndex]
					Armor Hands = akTarget.GetWornForm(0x08) as Armor
					If !Hands
						akTarget.EquipItem(HandsArmor, false, true)
					EndIf
					NiOverride.AddSkinOverrideString(akTarget, IsFemale, false, 0x04, 9, 1, MaleNormals[iIndex], True)
					iIndex = -1
				EndIf
				iIndex -= 1
			EndWhile
		EndIf
		;NiOverride.UpdateModelWeight(akTarget)
		If StartingTex != FetchedTex
			NiOverride.ApplySkinOverrides(akTarget)
		EndIf
	EndIf

EndFunction

Function ThighNodeUpdate(Actor akTarget, Float afWeight)

	If akTarget.HasKeywordString("ActorTypeNPC")
		bool isFemale = IsFemale(akTarget)
		If ThighNodeChanges
			Float fPercent = afWeight / MaximumWeight
			if fpercent < 0.0
				fpercent = 0.0
			endif
			Float[] XYZ = New Float[3]
			Float fModifier = ThighNodeFactor * fPercent
			XYZ[1] = XYZ[1] - fModifier
			XYZ[0] = XYZ[0] - fModifier
			;Note, could affect placement of Weapon L Calf and Weapon R Calf nodes.
			NiOverride.AddNodeTransformRotation(akTarget, False, isFemale, "CME R Hip", MODKEY, XYZ)
			NiOverride.UpdateNodeTransform(akTarget, false, isFemale, "CME R Hip")
			XYZ = New Float[3]
			XYZ[1] = XYZ[1] + fModifier
			XYZ[0] = XYZ[0] + fModifier
			NiOverride.AddNodeTransformRotation(akTarget, False, isFemale, "CME L Hip", MODKEY, XYZ)
			NiOverride.UpdateNodeTransform(akTarget, false, isFemale, "CME L Hip")
		Else
			NiOverride.RemoveNodeTransformRotation(akTarget, False, isFemale, "CME R Hip", MODKEY)
			NiOverride.RemoveNodeTransformRotation(akTarget, False, isFemale, "CME L Hip", MODKEY)
		EndIf
	EndIf

EndFunction

Function ArmNodeUpdate(Actor akTarget, Float afWeight)

	If akTarget.HasKeywordString("ActorTypeNPC")
		bool isFemale = IsFemale(akTarget)
		If ArmNodeChanges
			Float fPercent = afWeight / MaximumWeight
			if fpercent < 0.0
				fpercent = 0.0
			endif
			Float[] XYZ = New Float[3]
			Float fModifier = ArmNodeFactor * fPercent
			XYZ[1] = XYZ[1] - fModifier
			XYZ[0] = XYZ[0] - fModifier
			NiOverride.AddNodeTransformRotation(akTarget, False, isFemale, "CME R Clavicle [RClv]", MODKEY, XYZ)
			NiOverride.UpdateNodeTransform(akTarget, false, isFemale, "CME R Clavicle [RClv]")
			NiOverride.AddNodeTransformRotation(akTarget, False, isFemale, "CME R Shoulder", MODKEY, XYZ)
			NiOverride.UpdateNodeTransform(akTarget, false, isFemale, "CME R Shoulder")
			XYZ = New Float[3]
			XYZ[1] = XYZ[1] + fModifier
			XYZ[0] = XYZ[0] + fModifier
			NiOverride.AddNodeTransformRotation(akTarget, False, isFemale, "CME L Clavicle [LClv]", MODKEY, XYZ)
			NiOverride.UpdateNodeTransform(akTarget, false, isFemale, "CME L Clavicle [LClv]")
			NiOverride.AddNodeTransformRotation(akTarget, False, isFemale, "CME L Shoulder", MODKEY, XYZ)
			NiOverride.UpdateNodeTransform(akTarget, false, isFemale, "CME L Shoulder")
		Else
			NiOverride.RemoveNodeTransformRotation(akTarget, False, isFemale, "CME R Clavicle [RClv]", MODKEY)
			NiOverride.RemoveNodeTransformRotation(akTarget, False, isFemale, "CME R Shoulder", MODKEY)
			NiOverride.RemoveNodeTransformRotation(akTarget, False, isFemale, "CME L Clavicle [LClv]", MODKEY)
			NiOverride.RemoveNodeTransformRotation(akTarget, False, isFemale, "CME L Shoulder", MODKEY)
		EndIf
	EndIf

EndFunction

bool Function addHighValueFood(Form food)
	int index = HighValueFood.find(food)
	if index >= 0 && index < HighValueFood.Length
        return true
    endIf

    index = HighValueFood.find(none)
    if index < 0 
        HighValueFood = Utility.ResizeFormArray(HighValueFood, 1+(3*HighValueFood.length/2), none)
		index = HighValueFood.find(none)
		if index < 0 
			return false
		endIf
    endIf

    HighValueFood[index] = food
	Log1(PREFIX, "addHighValueFood", Namer(food))
	GotoState("DefaultState")
	return true
endFunction

bool Function addNoValueFood(Form food)
	int index = NoValueFood.find(food)
	if index >= 0 && index < NoValueFood.Length
        return true
    endIf

    index = NoValueFood.find(none)
    if index < 0 
        NoValueFood = Utility.ResizeFormArray(NoValueFood, 1+(3*NoValueFood.length/2), none)
		index = NoValueFood.find(none)
		if index < 0 
			return false
		endIf
    endIf

    NoValueFood[index] = food
	Log1(PREFIX, "addNoValueFood", Namer(food))
	GotoState("DefaultState")
	return true
endFunction

bool Function addMorph(String name, float multHigh, float multLow, int iType)
	
	Int iMorphStart = 0
	Int iMorphEnd = 32
	
	;We divide our Morph arrays up by Female, Male and Creature. 
	;These iTypes correspond to these "segments", 0 female, 1 male, 2 creature.
	If iType == 1
		iMorphStart = 32
		iMorphEnd = 64
	ElseIf iType == 2
		iMorphStart = 64
		iMorphEnd = 96
	EndIf

	if MorphStrings.find(name, iMorphStart) < iMorphEnd \
	&& MorphStrings.find(name, iMorphStart) >= iMorphStart
		;This slider string is already in our segment, reject it.
		Debug.MessageBox("That slider is already used in this page.")
        return false
    endIf

    int index = MorphStrings.find("", iMorphStart)
	If index < iMorphStart || index >= iMorphEnd
		;There are no free elements available in this segment.
		Debug.MessageBox("You have already used the maximum amount of sliders on this page.")
		return false
	EndIf

    MorphStrings[index] = name
    MorphsHigh[index] = multHigh
    MorphsLow[index] = multLow

	return true
EndFunction

bool Function removeMorph(int iSliderIndex)
    MorphStrings[iSliderIndex] = ""
	MorphsHigh[iSliderIndex] = 0.0
	MorphsLow[iSliderIndex] = 0.0

	if iSliderIndex < 32
		CompactifyMorphs(0, 32)
	elseif iSliderIndex < 64
		CompactifyMorphs(32, 32)
	else
		CompactifyMorphs(64, 32)
	endIf

    return true
EndFunction

Function CompactifyMorphs(int first, int count)
	int firstBlank = MorphStrings.find("", first)
	int endPoint = first + count
	int i = firstBlank + 1
	
	while i < endPoint
		if MorphStrings[i] != ""
			MorphStrings[firstBlank] = MorphStrings[i]
			MorphsHigh[firstBlank] = MorphsHigh[i]
			MorphsLow[firstBlank] = MorphsLow[i]
			MorphStrings[i] = ""
			MorphsHigh[i] = 0.0
			MorphsLow[i] = 0.0
			firstBlank += 1
		endIf
		i += 1
	endWhile
EndFunction

int Function GetWeightApprox(Actor target)
	float diff = MaximumWeight - MinimumWeight
	float baseWeight = StorageUtil.GetFloatValue(target, MODKEY, 0.0)
	float weight = 100.0 + (baseWeight - MinimumWeight) * 150.0 / diff
	return weight as int
EndFunction

float Function GetLossPerDay()
	return 24.0 * WeightLoss / WeightRate
EndFunction

Function RunPatchups()
	;Debug.Notification("Scanning main plugins.")
	addNoValueFood(Game.GetFormFromFile(0x034CDF, "Skyrim.esm"))
	addNoValueFood(Game.GetFormFromFile(0x074A19, "Skyrim.esm"))

	addHighValueFood(Game.GetFormFromFile(0x064b30, "Skyrim.esm"))
	addHighValueFood(Game.GetFormFromFile(0x03AD72, "Skyrim.esm"))
	addHighValueFood(Game.GetFormFromFile(0x10394D, "Skyrim.esm"))
	addHighValueFood(Game.GetFormFromFile(0x0669A4, "Skyrim.esm"))
	addHighValueFood(Game.GetFormFromFile(0x0722BB, "Skyrim.esm"))
	addHighValueFood(Game.GetFormFromFile(0x00353C, "Hearthfires.esm"))

	if Game.IsPluginInstalled("RealisticNeedsAndDiseases.esp")
		;Debug.Notification("Scanning 'RealisticNeedsAndDiseases.esp'")
		addNoValueFood(Game.GetFormFromFile(0x0053EC, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x0053EE, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x0053F0, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x00FB99, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x00FB9B, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x00FBA0, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x0053E5, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x0053E7, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x0053E9, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x00FBA3, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x00FBA5, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x00FBA7, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x05B2BC, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x05B2BE, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x05B2C0, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047FAE, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047FB0, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047FB6, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x0B6DF3, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x0B6DF0, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x0B6DEE, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x005968, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x046497, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047F98, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047F9A, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047F96, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047F94, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047F8B, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047F89, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047F88, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x0449AB, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x069FBE, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047FA7, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047FA5, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047FA4, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047FA2, "RealisticNeedsAndDiseases.esp"))

		addHighValueFood(Game.GetFormFromFile(0x012C49, "RealisticNeedsAndDiseases.esp"))
	endIf

	if Game.IsPluginInstalled("Skyrim Immersive Creatures Special Edition.esp")
		;Debug.Notification("Scanning 'Skyrim Immersive Creatures Special Edition.esp'")
		addHighValueFood(Game.GetFormFromFile(0x00F5EA, "Skyrim Immersive Creatures Special Edition.esp"))
	endIf
		
	if Game.IsPluginInstalled("SunhelmSurvival.esp")
		;Debug.Notification("Scanning 'SunhelmSurvival.esp'")
		addNoValueFood(Game.GetFormFromFile(0x265BE3, "SunhelmSurvival.esp"))
		addNoValueFood(Game.GetFormFromFile(0x265BE7, "SunhelmSurvival.esp"))
		addNoValueFood(Game.GetFormFromFile(0x326258, "SunhelmSurvival.esp"))
		addNoValueFood(Game.GetFormFromFile(0x070897, "SunhelmSurvival.esp"))
		addNoValueFood(Game.GetFormFromFile(0x07AA96, "SunhelmSurvival.esp"))
		addNoValueFood(Game.GetFormFromFile(0x326252, "SunhelmSurvival.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4DE9AE, "SunhelmSurvival.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4DE9AF, "SunhelmSurvival.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4DE9B0, "SunhelmSurvival.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4EDCC1, "SunhelmSurvival.esp"))
	endIf

	if Game.IsPluginInstalled("Minineeds.esp")
		;Debug.Notification("Scanning 'Minineeds.esp'")
		addNoValueFood(Game.GetFormFromFile(0x003192, "Minineeds.esp"))
		addNoValueFood(Game.GetFormFromFile(0x003194, "Minineeds.esp"))
	endIf

	if Game.IsPluginInstalled("INeed.esp")
		;Debug.Notification("Scanning 'INeed.esp'")
		addNoValueFood(Game.GetFormFromFile(0x00437F, "INeed.esp"))
		addNoValueFood(Game.GetFormFromFile(0x00437D, "INeed.esp"))
		addNoValueFood(Game.GetFormFromFile(0x004376, "INeed.esp"))
		addNoValueFood(Game.GetFormFromFile(0x03B2C5, "INeed.esp"))
		addNoValueFood(Game.GetFormFromFile(0x03B2C8, "INeed.esp"))
		addNoValueFood(Game.GetFormFromFile(0x03B2CC, "INeed.esp"))
	endIf

	if Game.IsPluginInstalled("Hunterborn.esp")
		;Debug.Notification("Scanning 'Hunterborn.esp'")
		addNoValueFood(Game.GetFormFromFile(0x28CCFA, "Hunterborn.esp"))

		addHighValueFood(Game.GetFormFromFile(0x1C2257, "Hunterborn.esp"))
	endIf
		
	if Game.IsPluginInstalled("Complete Alchemy & Cooking Overhaul.esp")
		;Debug.Notification("Scanning 'Complete Alchemy & Cooking Overhaul.esp'")
		addNoValueFood(Game.GetFormFromFile(0xCCA111, "Update.esm"))
		addNoValueFood(Game.GetFormFromFile(0x4E3D21, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4E3D23, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4E3D25, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4E3D27, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4E3D29, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4E3D2B, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4E3D2D, "Complete Alchemy & Cooking Overhaul.esp"))		
		addNoValueFood(Game.GetFormFromFile(0x4B633B, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x50750A, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x50750B, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x50750D, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5DC3C2, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4FD2B7, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5DC3C0, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4FD2BA, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x46A34E, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x73499B, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D2185, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D2186, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D21A0, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D21A2, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D21A4, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D21A6, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D21A8, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D21AA, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D2188, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D2192, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D2194, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D2196, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D2198, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D219A, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D219C, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D219E, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5E14C8, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4FD2BC, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D72AF, "Complete Alchemy & Cooking Overhaul.esp"))

		addHighValueFood(Game.GetFormFromFile(0xCCA124, "Update.esm"))
		addHighValueFood(Game.GetFormFromFile(0xCCA143, "Update.esm"))
		addHighValueFood(Game.GetFormFromFile(0xCCA144, "Update.esm"))
		addHighValueFood(Game.GetFormFromFile(0xCCA120, "Update.esm"))
		
		addHighValueFood(Game.GetFormFromFile(0x9E0567, "Complete Alchemy & Cooking Overhaul.esp"))
		addHighValueFood(Game.GetFormFromFile(0x9E056A, "Complete Alchemy & Cooking Overhaul.esp"))
		addHighValueFood(Game.GetFormFromFile(0x9E056C, "Complete Alchemy & Cooking Overhaul.esp"))
		addHighValueFood(Game.GetFormFromFile(0x9E056E, "Complete Alchemy & Cooking Overhaul.esp"))
	endIf

	if Game.IsPluginInstalled("MilkModNEW.esp")
		;Debug.Notification("Scanning 'MilkModNEW.esp'")
		addNoValueFood(Game.GetFormFromFile(0x076D1D, "MilkModNEW.esp"))
		addNoValueFood(Game.GetFormFromFile(0x05311B, "MilkModNEW.esp"))
		addNoValueFood(Game.GetFormFromFile(0x05820F, "MilkModNEW.esp"))
	endIf

	;Debug.MessageBox("Patchup Complete")
EndFunction

Bool Function LoadSettings()
	int data = JValue_readFromFile(SettingsFileName)
	if !JValue_isExists(data)
		return false
	endIf

	PlayerEnabled =			JMap_GetInt(data, "PlayerEnabled", PlayerEnabled as int) as bool
	NPCsEnabled =			JMap_GetInt(data, "NPCsEnabled", NPCsEnabled as int) as bool
	WeightLoss =			JMap_GetFlt(data, "WeightLoss", WeightLoss)
	WeightRate =			JMap_GetFlt(data, "WeightRate", WeightRate)
	MaximumWeight =			JMap_GetFlt(data, "MaximumWeight", MaximumWeight)
	MinimumWeight =			JMap_GetFlt(data, "MinimumWeight", MinimumWeight)
	IngredientBaseGain =	JMap_GetFlt(data, "IngredientBaseGain", IngredientBaseGain)
	PotionBaseGain =		JMap_GetFlt(data, "PotionBaseGain", PotionBaseGain)
	FoodBaseGain =			JMap_GetFlt(data, "FoodBaseGain", FoodBaseGain)
	HighValueMultiplier = 	JMap_GetFlt(data, "HighValueMultiplier", HighValueMultiplier)

	MorphStrings = JArray_asStringArray(JMap_getObj(data, "MorphStrings", JArray_ObjectWithStrings(MorphStrings)))
	MorphsHigh = JArray_asFloatArray(JMap_getObj(data, "MorphsHigh", JArray_ObjectWithFloats(MorphsHigh)))
	MorphsLow = JArray_asFloatArray(JMap_getObj(data, "MorphsLow", JArray_ObjectWithFloats(MorphsLow)))
	HighValueFood = JArray_asFormArray(JMap_getObj(data, "HighValueFood", JArray_ObjectWithForms(HighValueFood)))
	NoValueFood = JArray_asFormArray(JMap_getObj(data, "NoValueFood", JArray_ObjectWithForms(NoValueFood)))

    if MorphStrings.length < 96 || MorphsHigh.length < 96 || MorphsLow.length < 96
        MorphStrings = Utility.ResizeStringArray(MorphStrings, 96)
        MorphsHigh = Utility.ResizeFloatArray(MorphsHigh, 96)
        MorphsLow = Utility.ResizeFloatArray(MorphsLow, 96)
    endIf
	return true
EndFunction

Bool Function SaveSettings()
	int data = JMap_object()
	JMap_SetInt(data, "PlayerEnabled", 			PlayerEnabled as int) as bool
	JMap_SetInt(data, "NPCsEnabled", 			NPCsEnabled as int) as bool
	JMap_SetFlt(data, "WeightLoss", 			WeightLoss)
	JMap_SetFlt(data, "WeightRate", 			WeightRate)
	JMap_SetFlt(data, "MaximumWeight", 			MaximumWeight)
	JMap_SetFlt(data, "MinimumWeight", 			MinimumWeight)
	JMap_SetFlt(data, "IngredientBaseGain", 	IngredientBaseGain)
	JMap_SetFlt(data, "PotionBaseGain", 		PotionBaseGain)
	JMap_SetFlt(data, "FoodBaseGain", 			FoodBaseGain)
	JMap_SetFlt(data, "HighValueMultiplier", 	HighValueMultiplier)
	JMap_SetObj(data, "MorphStrings", 			JArray_objectWithStrings(MorphStrings))
	JMap_SetObj(data, "MorphsHigh", 			JArray_objectWithFloats(MorphsHigh))
	JMap_SetObj(data, "MorphsLow", 				JArray_objectWithFloats(MorphsLow))
	JMap_SetObj(data, "HighValueFood", 			JArray_objectWithForms(HighValueFood))
	JMap_SetObj(data, "NoValueFood", 			JArray_objectWithForms(NoValueFood))
	JValue_writeToFile(data, SettingsFileName)
	return JContainers.fileExistsAtPath(SettingsFileName)
EndFunction

;/
Function Upgrade(int oldVersion, int newVersion)
	Log2(PREFIX, "Upgrade", oldVersion, newVersion)
	
	if oldVersion > 0 && oldVersion != newVersion
		ResetActorWeights()
	endIf
EndFunction
/;
	
;/
WinterweightCore Function instance() global
	Return self as WinterweightCore
EndFunction
/;