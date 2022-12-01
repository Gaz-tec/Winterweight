Scriptname WinterweightRemoveItemQuest Extends Quest
{
AUTHOR: Gaz
PURPOSE: StoryManager fired script, hooked to PlayerRemoveItems node. Makes nearest companion eat dropped food.
}

ReferenceAlias Property Companion Auto
ReferenceAlias Property Item Auto
ReferenceAlias Property Player Auto

Event OnStoryRemoveFromPlayer(ObjectReference akOwner, ObjectReference akItem, Location akLocation, Form akItemBase, int aiRemoveType)

    If aiRemoveType == 4    ;Dropped
        Actor kCompanion = Companion.GetReference() as Actor
        If kCompanion
            ObjectReference[] CloseFood = PO3_SKSEFunctions.FindAllReferencesWithKeyword(kCompanion, Game.GetForm(0x0008CDEA) as Keyword, 2100.0, false)
            Int iNearbyFoods = CloseFood.Length - 1
            ActorBase PlayerBase = Player.GetActorReference().GetActorBase()
            While iNearbyFoods > -1
                utility.wait(0.015)
                If CloseFood[iNearbyFoods].GetActorOwner() == PlayerBase
                    CloseFood[iNearbyFoods].Activate(kCompanion, true)
                    kCompanion.AddItem(CloseFood[iNearbyFoods].GetBaseObject(), 1, true)
                    int handle = ModEvent.create("Winterweight_ItemConsume")
                    ModEvent.pushForm(handle, kCompanion as Form)
                    ModEvent.pushForm(handle, CloseFood[iNearbyFoods].GetBaseObject())
                    ModEvent.pushInt(handle, 1)
                    ModEvent.Send(handle)
                    kCompanion.EquipItem(CloseFood[iNearbyFoods].GetBaseObject())
                    CloseFood[iNearbyFoods].Delete()
                EndIf
                iNearbyFoods -= 1
            EndWhile
        EndIf
    EndIf
    Self.Stop()
EndEvent