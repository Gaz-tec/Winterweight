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
Armor Property TailArmor Auto
WinterweightMCM Property WinterMCM Auto

String[] Property FemaleSliderStrings auto
Float[] Property FemaleSliderHighs auto
Float[] Property FemaleSliderLows auto

String[] Property MaleSliderStrings auto
Float[] Property MaleSliderHighs auto
Float[] Property MaleSliderLows auto

String[] Property CreatureSliderStrings auto
Float[] Property CreatureSliderHighs auto
Float[] Property CreatureSliderLows auto

GlobalVariable Property GameDaysPassed Auto	;Vanilla global.
GlobalVariable Property DropFeeding Auto

Form[] Property HighValueFood Auto
Form[] Property NoValueFood Auto
Keyword Property ActorTypeCreature Auto

Bool Property ModEnabled = False Auto
Bool Property PlayerEnabled = True Auto Hidden
Bool Property NPCsEnabled = True Auto Hidden
Bool Property ArmNodeChanges = True Auto Hidden
Bool Property ThighNodeChanges = True Auto Hidden
Bool Property TailNodeChanges = False Auto Hidden
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
Float Property TailNodeFactor = 16.0 Auto Hidden
Float Property IngredientBaseGain = 0.04 Auto Hidden
Float Property PotionBaseGain = 0.02 Auto Hidden
Float Property FoodBaseGain = 0.10 Auto Hidden
Float Property VoreBaseGain = 0.9 Auto Hidden
Float Property HighValueMultiplier = 2.0 Auto Hidden
Quest Property RefactorManager = None Auto Hidden	

Actor[] Property Gainers Auto

String[] Property FemaleNormals Auto Hidden
String[] Property FemaleArgonianNormals Auto Hidden
String[] Property FemaleKhajiitNormals Auto Hidden
String[] Property MaleNormals Auto Hidden
String[] Property MaleArgonianNormals Auto Hidden
String[] Property MaleKhajiitNormals Auto Hidden
String Property SettingsFileName = "data\\skse\\plugins\\winterweight\\settings.json" autoreadonly Hidden

String MODKEY = "Winterweight.esp"
String PREFIX = "WinterweightCore"

String CMETails = "CME Tail Pelvis [Pelv]"

;Bool DetectedSleepEvent = False

;Float SleepStartHour = 0.0
;Float SleepEndHour = 0.0
Bool UpdateMutex = False
Float LastGameHours = 0.0
Int Ticks = 0	;Holding variable for Ticks since last processed while we're doing WeightLoss.

Event OnInit()
	EventRegistration()
	FemaleNormals = New String[3]
	FemaleArgonianNormals = New String[3]
	FemaleKhajiitNormals = New String[3]
	FemaleNormals[0] = "Actors\\Character\\Female\\FemaleBody_1_msn.dds"
	FemaleArgonianNormals[0] = "Actors\\Character\\argonianfemale\\argonianfemalebody_msn.dds"
	FemaleKhajiitNormals[0] = "Actors\\Character\\khajiitfemale\\femalebody_msn.dds"
	FemaleNormals[1] = "Actors\\Character\\Winterweight\\Female\\FemaleBody_chubby1_msn.dds"
	;FemaleArgonianNormals[1] = "Actors\\Character\\\argonianfemale\\argonianfemalebody_msn.dds"
	;FemaleKhajiitNormals[1] = "Actors\\Character\\khajiitfemale\\femalebody_msn.dds"
	FemaleNormalBreakpoints = New Float[3]
	FemaleNormalBreakpoints[1] = 1.0
	FemaleNormalBreakpoints[2] = 1.5

	MaleNormals = New String[3]
	MaleArgonianNormals = New String[3]
	MaleKhajiitNormals = New String[3]
	MaleNormals[0] = "Actors\\Character\\Male\\MaleBody_1_msn.dds"
	MaleArgonianNormals[0] = "Actors\\Character\\argonianmale\\argonianmalebody_msn.dds"
	MaleKhajiitNormals[0] = "Actors\\Character\\khajiitmale\\malebody_msn.dds"
	MaleNormalBreakpoints = New Float[3]
	MaleNormalBreakpoints[1] = 1.0
	MaleNormalBreakpoints[2] = 1.5

	if FemaleSliderStrings.length < 128 || FemaleSliderHighs.length < 128 || FemaleSliderLows.length < 128
        FemaleSliderStrings = Utility.ResizeStringArray(FemaleSliderStrings, 128)
        FemaleSliderHighs = Utility.ResizeFloatArray(FemaleSliderHighs, 128)
        FemaleSliderLows = Utility.ResizeFloatArray(FemaleSliderLows, 128)
    endIf

	if MaleSliderStrings.length < 128 || MaleSliderHighs.length < 128 || MaleSliderLows.length < 128
        MaleSliderStrings = Utility.ResizeStringArray(MaleSliderStrings, 128)
        MaleSliderHighs = Utility.ResizeFloatArray(MaleSliderHighs, 128)
        MaleSliderLows = Utility.ResizeFloatArray(MaleSliderLows, 128)
    endIf

	if CreatureSliderStrings.length < 128 || CreatureSliderHighs.length < 128 || CreatureSliderLows.length < 128
        CreatureSliderStrings = Utility.ResizeStringArray(CreatureSliderStrings, 128)
        CreatureSliderHighs = Utility.ResizeFloatArray(CreatureSliderHighs, 128)
        CreatureSliderLows = Utility.ResizeFloatArray(CreatureSliderLows, 128)
    endIf

	Gainers = PapyrusUtil.ActorArray(128)
	
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
	If RefactorManager != None
		RegisterForModEvent("Devourment_OnDeadDigestion", "DeadDigest")
        RegisterForModEvent("Devourment_onConsumeItem", "RefactorItemConsume")
	Else
		UnregisterForModEvent("Devourment_OnDeadDigestion")
		UnregisterForModEvent("Devourment_onConsumeItem")
	EndIf
EndFunction

Event DeadDigest(Form f1, Form f2, float remaining)
	;Prevents gaining weight from prey that are reformed or fully digested.
	if remaining >= 100.0 || remaining < 0.0
		return
	endIf

    Actor pred = f1 as Actor
    Actor prey = f2 as Actor
    
	If !pred && !prey
        return
    endIf

	Float fRemaining = StorageUtil.GetFloatValue(prey, PREFIX + "ProcessedLast", 100.0)
	StorageUtil.SetFloatValue(prey, PREFIX + "ProcessedLast", remaining)

	Float fDelta = -remaining + fRemaining

	If fDelta != 0.0

		;We want the Vore Weight Ratio so we know relatively "how big a deal" the preys size is to the preds.
		;A huge pred eating a small prey should gain little weight and vice versa.
		DevourmentManager Manager = RefactorManager as DevourmentManager
		Float fRatio = Manager.GetVoreWeightRatio(pred, prey)

		ConsoleUtil.PrintMessage("DeadDigest worth: ("+VoreBaseGain / 100+") / ("+fRatio+ "+" +1.0+")) *" +fDelta+ ")")

		;This will fire every tick of digestion so set it low and gradual.
		;It would be much less computationally heavy to just wait until Digestion is over
		;and *then* do this, but people want fidelity, to see the WG in action as they digest things.
		ChangeActorWeight(pred, ((VoreBaseGain / 100) / (fRatio + 1.0)) * fDelta)
	EndIf
EndEvent

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
	if returnticks <= 0
		returnticks = 1
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
		Int iIndex = 0
		While iIndex < Gainers.Length
			If Gainers[iIndex] != None
				ActorWeightLoss(Gainers[iIndex])
			EndIf
			iIndex += 1
		EndWhile
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

Event RefactorItemConsume(Form consumer, Form itemBase, int count)
{Same parameters as regular ItemConsume but checks if Actor is Player, as by default WinterWeight looks for Player Equip Events and would receive duplicate.}

	If (Consumer as Actor) != PlayerRef
		ItemConsume(consumer, itemBase, count)
	EndIf

EndEvent

Event ItemConsume(Form consumer, Form itemBase, int count)
{Event that fires when Actors consume something via Feeding. Also called for Player Equip events.}

	If ModEnabled
		If consumer == None
			Return
		EndIf

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
				ConsoleUtil.PrintMessage("Got high value food equip event worth: " +((FoodBaseGain * baseWeight) * HighValueMultiplier)+ " " +Namer(itemBase))
				ChangeActorWeight(gainer, (FoodBaseGain * baseWeight) * HighValueMultiplier)
			else
				ConsoleUtil.PrintMessage("Got food equip event worth: " +(FoodBaseGain * baseWeight)+ " " +Namer(itemBase))
				ChangeActorWeight(gainer, (FoodBaseGain * baseWeight))
			EndIf
			;Manager.RegisterFakeDigestion(gainer, baseWeight * 2.0)

		ElseIf PotionBaseGain > 0.0 && itemBase.HasKeywordString("VendorItemPotion")
			ConsoleUtil.PrintMessage("Got potion equip event worth: " +PotionBaseGain+ " " +Namer(itemBase))
			ChangeActorWeight(gainer, PotionBaseGain)
			;Manager.RegisterFakeDigestion(gainer, baseWeight)
			
		ElseIf IngredientBaseGain > 0.0 && itemBase as Ingredient
			ConsoleUtil.PrintMessage("Got ingredient equip event worth: " +(IngredientBaseGain * baseWeight)+ " " +Namer(itemBase))
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

		FullFeatureUpdate(target, 0.0)

		NiOverride.ClearBodyMorphKeys(target, MODKEY)
		NiOverride.ClearBodyMorphKeys(target, MODKEY)	;Call twice, since sometimes this one seems to fail on first call.
		NiOverride.UpdateModelWeight(target)

		StorageUtil.UnSetFloatValue(target, MODKEY)

	endIf
EndFunction

Function ResetActorWeights()
	NiOverride.ForEachMorphedReference("ResetActorWeight", WinterMCM)
EndFunction

float Function GetCurrentActorWeight(Actor target)
	return StorageUtil.GetFloatValue(target, MODKEY, 0.0)
EndFunction

bool Function IsFemale(Actor target)
	return target.getLeveledActorBase().getSex()
EndFunction

Bool Function ChangeActorWeight(Actor target, float afChange, float afSplitThreshold = 0.025)
{All-purpose function for losing and gaining Weight.}

	If !ModEnabled || target == None
		Return False
	ElseIf target == PlayerRef && (PlayerEnabled == False)
		Return False
	ElseIf target != PlayerRef && (NPCsEnabled == False)
		Return False
	EndIf

	If Gainers.Find(target) == -1
		int iIndex = Gainers.Find(None)
		Gainers[iIndex] = target
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
			FullFeatureUpdate(Target, Current)
		EndWhile
		StorageUtil.SetFloatValue(NextGainer, MODKEY, Current)
		NextGainer = StorageUtil.FormListShift(None, MODKEY)
	EndWhile

	UpdateMutex = False

EndFunction

Function FullFeatureUpdate(Actor akTarget, Float afWeight)
{Convenience function to call all visual features on the Actor to update.}

	BodyMorphUpdate(akTarget, afWeight)
	ArmNodeUpdate(akTarget, afWeight)
	ThighNodeUpdate(akTarget, afWeight)
	TailNodeUpdate(akTarget, afWeight)
	NormalMapUpdate(akTarget, afWeight)

EndFunction

Function BodyMorphUpdate(Actor akTarget, Float afWeight)

	String[] SliderStrings
	Float[] SliderLows
	Float[] SliderHighs

	int iSlider = 0
	bool isFemale = IsFemale(akTarget)

	If !akTarget.HasKeyword(ActorTypeCreature)
		If isFemale
			SliderStrings = FemaleSliderStrings
			SliderLows = FemaleSliderLows
			SliderHighs = FemaleSliderHighs
		Else
			SliderStrings = MaleSliderStrings
			SliderLows = MaleSliderLows
			SliderHighs = MaleSliderHighs
		EndIf
	Else
		SliderStrings = CreatureSliderStrings
		SliderLows = CreatureSliderLows
		SliderHighs = CreatureSliderHighs
	EndIf

	int endPoint = SliderStrings.Length

	if afWeight < 0.0	;Targets need to be inverted for the sliders to end up at correct values if target is below 0.0 weight.
		While iSlider < endPoint && SliderStrings[iSlider] != ""
			NiOverride.SetBodyMorph(akTarget, SliderStrings[iSlider], MODKEY, -(afWeight / MinimumWeight) * SliderLows[iSlider])
			iSlider += 1
		EndWhile
	else
		While iSlider < endPoint && SliderStrings[iSlider] != ""
			NiOverride.SetBodyMorph(akTarget, SliderStrings[iSlider], MODKEY, (afWeight / MaximumWeight) * SliderHighs[iSlider])
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
					If akTarget.HasKeywordString("IsBeastRace")
						Int TargetRace = akTarget.GetLeveledActorBase().GetRace().GetFormID()
						;If target race is Argonian, ArgonianVampire, Khajiit or KhajiitVampire.
						If TargetRace == 79680 || TargetRace == 559162 || TargetRace == 79685 || TargetRace == 559173
							akTarget.EquipItem(TailArmor, false, true)
						EndIf
					EndIf
					NiOverride.AddSkinOverrideString(akTarget, IsFemale, false, 0x04, 9, 1, FemaleNormals[iIndex], True)
					
					;NiOverride.AddSkinOverrideString(akTarget, IsFemale, false, 0x08, 9, 1, "Textures\\Actors\\Character\\Female\\FemaleHands_1_msn.dds", True)
					;NiOverride.AddSkinOverrideString(akTarget, IsFemale, false, 0x04, 9, 1, "Textures\\"+FemaleNormals[iIndex], True)
					;NiOverride.AddNodeOverrideTextureSet(akTarget, IsFemale, "3BAv2", 9, 1, WinterweightSkinBodyFemale, True)
					;NiOverride.AddNodeOverrideString(akTarget, IsFemale, "3BAv2", 9, 1, FemaleNormals[iIndex], False)
					;NiOverride.ApplyNodeOverrides(akTarget)
					iIndex = -1	;We applied a higher Normal, now leave it alone and exit.
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
					If akTarget.HasKeywordString("IsBeastRace")
						Int TargetRace = akTarget.GetLeveledActorBase().GetRace().GetFormID()
						;If target race is Argonian, ArgonianVampire, Khajiit or KhajiitVampire.
						If TargetRace == 79680 || TargetRace == 559162 || TargetRace == 79685 || TargetRace == 559173
							akTarget.EquipItem(TailArmor, false, true)
						EndIf
					EndIf
					NiOverride.AddSkinOverrideString(akTarget, IsFemale, false, 0x04, 9, 1, MaleNormals[iIndex], True)
					iIndex = -1 ;We applied a higher Normal, now leave it alone and exit.
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

Function TailNodeUpdate(Actor akTarget, Float afWeight)

	If akTarget.HasKeywordString("ActorTypeNPC")
		bool isFemale = IsFemale(akTarget)
		Float fPercent = afWeight / MaximumWeight
			if fpercent < 0.0
				fpercent = 0.0
			endif
		If TailNodeChanges
			
			Float[] XYZ = New Float[3]
			Float fModifier = (TailNodeFactor * fPercent)
			;XYZ[1] = ((XYZ[1] + fModifier) / 4) * -1	;Out
			
			XYZ[2] = XYZ[2] + fModifier	;Up
			NiOverride.AddNodeTransformPosition(akTarget, False, isFemale, CMETails, MODKEY, XYZ)
			NiOverride.UpdateNodeTransform(akTarget, false, isFemale, CMETails)
		Else
			NiOverride.RemoveNodeTransformPosition(akTarget, False, isFemale, CMETails, MODKEY)
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
	
	;These iTypes correspond to: 0 female, 1 male, 2 creature.
	If iType == 0
		if FemaleSliderStrings.find(name) > -1
			Debug.MessageBox("That slider is already used in this page.")
			return false
		endIf
	
		Int iIndex = FemaleSliderStrings.find("")
		If iIndex == -1
			Debug.MessageBox("You have already used the maximum amount of sliders.")
			return false
		EndIf
	
		FemaleSliderStrings[iIndex] = name
		FemaleSliderLows[iIndex] = multLow
		FemaleSliderHighs[iIndex] = multHigh
	ElseIf iType == 1
		if MaleSliderStrings.find(name) > -1
			Debug.MessageBox("That slider is already used in this page.")
			return false
		endIf
	
		Int iIndex = MaleSliderStrings.find("")
		If iIndex == -1
			Debug.MessageBox("You have already used the maximum amount of sliders.")
			return false
		EndIf
	
		MaleSliderStrings[iIndex] = name
		MaleSliderLows[iIndex] = multLow
		MaleSliderHighs[iIndex] = multHigh
	ElseIf iType == 2
		if CreatureSliderStrings.find(name) > -1
			Debug.MessageBox("That slider is already used in this page.")
			return false
		endIf
	
		Int iIndex = CreatureSliderStrings.find("")
		If iIndex == -1
			Debug.MessageBox("You have already used the maximum amount of sliders.")
			return false
		EndIf
	
		CreatureSliderStrings[iIndex] = name
		CreatureSliderLows[iIndex] = multLow
		CreatureSliderHighs[iIndex] = multHigh
	EndIf

	return true
EndFunction

bool Function removeMorph(int iIndex, int iType)
	;These iTypes correspond to: 0 female, 1 male, 2 creature.

	If iType == 0
		FemaleSliderStrings[iIndex] = ""
		FemaleSliderLows[iIndex] = 0.0
		FemaleSliderHighs[iIndex] = 0.0
	ElseIf iType == 1
		MaleSliderStrings[iIndex] = ""
		MaleSliderLows[iIndex] = 0.0
		MaleSliderHighs[iIndex] = 0.0
	ElseIf iType == 2
		CreatureSliderStrings[iIndex] = ""
		CreatureSliderLows[iIndex] = 0.0
		CreatureSliderHighs[iIndex] = 0.0
	EndIf

	CompactifyMorphs(iType)

    return true
EndFunction

Function CompactifyMorphs(int iType)
	If iType == 0
		Int iFirstBlank = FemaleSliderStrings.find("")
		Int i = iFirstBlank + 1
		Int iLength = FemaleSliderStrings.Length
		while i < iLength
			if FemaleSliderStrings[i] != ""
				FemaleSliderStrings[iFirstBlank] = FemaleSliderStrings[i]
				FemaleSliderHighs[iFirstBlank] = FemaleSliderHighs[i]
				FemaleSliderLows[iFirstBlank] = FemaleSliderLows[i]
				FemaleSliderStrings[i] = ""
				FemaleSliderHighs[i] = 0.0
				FemaleSliderLows[i] = 0.0
				iFirstBlank += 1
			endIf
			i += 1
		endWhile
	ElseIf iType == 1
		Int iFirstBlank = MaleSliderStrings.find("")
		Int i = iFirstBlank + 1
		Int iLength = MaleSliderStrings.Length
		while i < iLength
			if MaleSliderStrings[i] != ""
				MaleSliderStrings[iFirstBlank] = MaleSliderStrings[i]
				MaleSliderHighs[iFirstBlank] = MaleSliderHighs[i]
				MaleSliderLows[iFirstBlank] = MaleSliderLows[i]
				MaleSliderStrings[i] = ""
				MaleSliderHighs[i] = 0.0
				MaleSliderLows[i] = 0.0
				iFirstBlank += 1
			endIf
			i += 1
		endWhile
	ElseIf iType == 2
		Int iFirstBlank = CreatureSliderStrings.find("")
		Int i = iFirstBlank + 1
		Int iLength = CreatureSliderStrings.Length
		while i < iLength
			if CreatureSliderStrings[i] != ""
				CreatureSliderStrings[iFirstBlank] = CreatureSliderStrings[i]
				CreatureSliderHighs[iFirstBlank] = CreatureSliderHighs[i]
				CreatureSliderLows[iFirstBlank] = CreatureSliderLows[i]
				CreatureSliderStrings[i] = ""
				CreatureSliderHighs[i] = 0.0
				CreatureSliderLows[i] = 0.0
				iFirstBlank += 1
			endIf
			i += 1
		endWhile
	EndIf
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

	ModEnabled =			JMap_GetInt(data, "ModEnabled", ModEnabled as int) as bool
	PlayerEnabled =			JMap_GetInt(data, "PlayerEnabled", PlayerEnabled as int) as bool
	NPCsEnabled =			JMap_GetInt(data, "NPCsEnabled", NPCsEnabled as int) as bool
	ArmNodeChanges = 		JMap_GetInt(data, "ArmNodeChanges", ArmNodeChanges as int) as bool
	ThighNodeChanges = 		JMap_GetInt(data, "ThighNodeChanges", ThighNodeChanges as int) as bool
	TailNodeChanges = 		JMap_GetInt(data, "TailNodeChanges", TailNodeChanges as int) as bool
	FemaleNormalChanges = 		JMap_GetInt(data, "FemaleNormalChanges", FemaleNormalChanges as int) as bool
	MaleNormalChanges = 		JMap_GetInt(data, "MaleNormalChanges", MaleNormalChanges as int) as bool
	FemaleNormalBreakpoints = JArray_asFloatArray(JMap_getObj(data, "FemaleNormalBreakpoints", JArray_ObjectWithFloats(FemaleNormalBreakpoints)))
	MaleNormalBreakpoints = JArray_asFloatArray(JMap_getObj(data, "MaleNormalBreakpoints", JArray_ObjectWithFloats(MaleNormalBreakpoints)))
	FemaleNormals = JArray_asStringArray(JMap_getObj(data, "FemaleNormals", JArray_ObjectWithStrings(FemaleNormals)))
	MaleNormals = JArray_asStringArray(JMap_getObj(data, "MaleNormals", JArray_ObjectWithStrings(MaleNormals)))
	ArmNodeFactor =			JMap_GetFlt(data, "ArmNodeFactor", ArmNodeFactor)
	ThighNodeFactor =			JMap_GetFlt(data, "ThighNodeFactor", ThighNodeFactor)
	TailNodeFactor =			JMap_GetFlt(data, "TailNodeFactor", TailNodeFactor)
	DropFeeding.SetValue(JMap_GetFlt(data, "DropFeeding", DropFeeding.GetValue()))
	WeightLossEnabled =			JMap_GetInt(data, "WeightLossEnabled", WeightLossEnabled as int) as bool
	WeightLoss =			JMap_GetFlt(data, "WeightLoss", WeightLoss)
	WeightRate =			JMap_GetFlt(data, "WeightRate", WeightRate)
	MaximumWeight =			JMap_GetFlt(data, "MaximumWeight", MaximumWeight)
	MinimumWeight =			JMap_GetFlt(data, "MinimumWeight", MinimumWeight)
	IngredientBaseGain =	JMap_GetFlt(data, "IngredientBaseGain", IngredientBaseGain)
	PotionBaseGain =		JMap_GetFlt(data, "PotionBaseGain", PotionBaseGain)
	FoodBaseGain =			JMap_GetFlt(data, "FoodBaseGain", FoodBaseGain)
	VoreBaseGain =			JMap_GetFlt(data, "VoreBaseGain", VoreBaseGain)
	HighValueMultiplier = 	JMap_GetFlt(data, "HighValueMultiplier", HighValueMultiplier)

	FemaleSliderStrings = JArray_asStringArray(JMap_getObj(data, "FemaleSliderStrings", JArray_ObjectWithStrings(FemaleSliderStrings)))
	FemaleSliderHighs = JArray_asFloatArray(JMap_getObj(data, "FemaleSliderHighs", JArray_ObjectWithFloats(FemaleSliderHighs)))
	FemaleSliderLows = JArray_asFloatArray(JMap_getObj(data, "FemaleSliderLows", JArray_ObjectWithFloats(FemaleSliderLows)))

	MaleSliderStrings = JArray_asStringArray(JMap_getObj(data, "MaleSliderStrings", JArray_ObjectWithStrings(MaleSliderStrings)))
	MaleSliderHighs = JArray_asFloatArray(JMap_getObj(data, "MaleSliderHighs", JArray_ObjectWithFloats(MaleSliderHighs)))
	MaleSliderLows = JArray_asFloatArray(JMap_getObj(data, "MaleSliderLows", JArray_ObjectWithFloats(MaleSliderLows)))

	CreatureSliderStrings = JArray_asStringArray(JMap_getObj(data, "CreatureSliderStrings", JArray_ObjectWithStrings(CreatureSliderStrings)))
	CreatureSliderHighs = JArray_asFloatArray(JMap_getObj(data, "CreatureSliderHighs", JArray_ObjectWithFloats(CreatureSliderHighs)))
	CreatureSliderLows = JArray_asFloatArray(JMap_getObj(data, "CreatureSliderLows", JArray_ObjectWithFloats(CreatureSliderLows)))

	HighValueFood = JArray_asFormArray(JMap_getObj(data, "HighValueFood", JArray_ObjectWithForms(HighValueFood)))
	NoValueFood = JArray_asFormArray(JMap_getObj(data, "NoValueFood", JArray_ObjectWithForms(NoValueFood)))

    if FemaleSliderStrings.length < 128 || FemaleSliderHighs.length < 128 || FemaleSliderLows.length < 128
        FemaleSliderStrings = Utility.ResizeStringArray(FemaleSliderStrings, 128)
        FemaleSliderHighs = Utility.ResizeFloatArray(FemaleSliderHighs, 128)
        FemaleSliderLows = Utility.ResizeFloatArray(FemaleSliderLows, 128)
    endIf

	if MaleSliderStrings.length < 128 || MaleSliderHighs.length < 128 || MaleSliderLows.length < 128
        MaleSliderStrings = Utility.ResizeStringArray(MaleSliderStrings, 128)
        MaleSliderHighs = Utility.ResizeFloatArray(MaleSliderHighs, 128)
        MaleSliderLows = Utility.ResizeFloatArray(MaleSliderLows, 128)
    endIf

	if CreatureSliderStrings.length < 128 || CreatureSliderHighs.length < 128 || CreatureSliderLows.length < 128
        CreatureSliderStrings = Utility.ResizeStringArray(CreatureSliderStrings, 128)
        CreatureSliderHighs = Utility.ResizeFloatArray(CreatureSliderHighs, 128)
        CreatureSliderLows = Utility.ResizeFloatArray(CreatureSliderLows, 128)
    endIf
	return true
EndFunction

Bool Function SaveSettings()
	int data = JMap_object()
	JMap_SetInt(data, "ModEnabled", 				ModEnabled as int) as bool
	JMap_SetInt(data, "PlayerEnabled", 				PlayerEnabled as int) as bool
	JMap_SetInt(data, "NPCsEnabled", 				NPCsEnabled as int) as bool
	JMap_SetInt(data, "ArmNodeChanges", 			ArmNodeChanges as Int) as Bool
	JMap_SetInt(data, "ThighNodeChanges", 			ThighNodeChanges as Int) as Bool
	JMap_SetInt(data, "TailNodeChanges", 			TailNodeChanges as Int) as Bool
	JMap_SetInt(data, "FemaleNormalChanges", 		FemaleNormalChanges as Int) as Bool
	JMap_SetInt(data, "MaleNormalChanges", 			MaleNormalChanges as Int) as Bool
	JMap_SetObj(data, "FemaleNormalBreakpoints", 	JArray_objectWithFloats(FemaleNormalBreakpoints))
	JMap_SetObj(data, "MaleNormalBreakpoints", 		JArray_objectWithFloats(MaleNormalBreakpoints))
	JMap_SetObj(data, "FemaleNormals", 				JArray_objectWithStrings(FemaleNormals))
	JMap_SetObj(data, "MaleNormals", 				JArray_objectWithStrings(MaleNormals))
	JMap_SetFlt(data, "ArmNodeFactor", 				ArmNodeFactor)
	JMap_SetFlt(data, "ThighNodeFactor", 			ThighNodeFactor)
	JMap_SetFlt(data, "TailNodeFactor", 			TailNodeFactor)
	JMap_SetFlt(data, "DropFeeding", 				DropFeeding.GetValue())

	JMap_SetInt(data, "WeightLossEnabled", 			WeightLossEnabled as int) as bool
	JMap_SetFlt(data, "WeightLoss", 			WeightLoss)
	JMap_SetFlt(data, "WeightRate", 			WeightRate)
	JMap_SetFlt(data, "MaximumWeight", 			MaximumWeight)
	JMap_SetFlt(data, "MinimumWeight", 			MinimumWeight)
	JMap_SetFlt(data, "IngredientBaseGain", 	IngredientBaseGain)
	JMap_SetFlt(data, "PotionBaseGain", 		PotionBaseGain)
	JMap_SetFlt(data, "FoodBaseGain", 			FoodBaseGain)

	JMap_SetFlt(data, "VoreBaseGain", 			VoreBaseGain)
	JMap_SetFlt(data, "HighValueMultiplier", 	HighValueMultiplier)
	JMap_SetObj(data, "FemaleSliderStrings", 	JArray_objectWithStrings(FemaleSliderStrings))
	JMap_SetObj(data, "FemaleSliderHighs", 		JArray_objectWithFloats(FemaleSliderHighs))
	JMap_SetObj(data, "FemaleSliderLows", 		JArray_objectWithFloats(FemaleSliderLows))
	JMap_SetObj(data, "MaleSliderStrings", 		JArray_objectWithStrings(MaleSliderStrings))
	JMap_SetObj(data, "MaleSliderHighs", 		JArray_objectWithFloats(MaleSliderHighs))
	JMap_SetObj(data, "MaleSliderLows", 		JArray_objectWithFloats(MaleSliderLows))
	JMap_SetObj(data, "CreatureSliderStrings", 	JArray_objectWithStrings(CreatureSliderStrings))
	JMap_SetObj(data, "CreatureSliderHighs", 	JArray_objectWithFloats(CreatureSliderHighs))
	JMap_SetObj(data, "CreatureSliderLows", 	JArray_objectWithFloats(CreatureSliderLows))
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