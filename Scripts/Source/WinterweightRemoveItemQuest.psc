Scriptname WinterweightRemoveItemQuest Extends Quest
{
AUTHOR: Gaz
PURPOSE: StoryManager fired script, hooked to PlayerRemoveItems node. Makes nearest companion eat dropped food.
}

GlobalVariable Property DropFeedingAll Auto
ReferenceAlias Property Companion Auto
ReferenceAlias Property NPC Auto
ReferenceAlias Property Item Auto
ReferenceAlias Property Player Auto

Event OnStoryRemoveFromPlayer(ObjectReference akOwner, ObjectReference akItem, Location akLocation, Form akItemBase, int aiRemoveType)

    If aiRemoveType == 4    ;Dropped
        Float AllNPCs = DropFeedingAll.GetValue()
        Actor kCompanion = Companion.GetReference() as Actor
        Actor kNPC = NPC.GetReference() as Actor
        Actor PlayerRef = Player.GetActorReference()
        ;Debug.MessageBox("kCompanion: " +kCompanion.GetDisplayName()+ " kNPC: " +kNPC.GetDisplayName())
        If AllNPCs >= 1.0 && kNPC != None
            float fCompDis = kCompanion.GetDistance(Item.GetRef())
            If fCompDis > kNPC.GetDistance(Item.GetRef())
                kCompanion = kNPC
            EndIf
        EndIf
       
        If kCompanion
            ObjectReference[] CloseFood = PO3_SKSEFunctions.FindAllReferencesWithKeyword(kCompanion, Game.GetForm(0x0008CDEA) as Keyword, 2100.0, false)
            Int iNearbyFoods = CloseFood.Length - 1
            ActorBase PlayerBase = PlayerRef.GetActorBase()
            While iNearbyFoods > -1
                utility.wait(0.015)
                If CloseFood[iNearbyFoods].GetActorOwner() == PlayerBase || CloseFood[iNearbyFoods].GetParentCell().GetActorOwner() == PlayerBase || CloseFood[iNearbyFoods].GetFactionOwner() == None && CloseFood[iNearbyFoods].GetParentCell().GetFactionOwner() == None && CloseFood[iNearbyFoods].GetActorOwner() == None && CloseFood[iNearbyFoods].GetParentCell().GetActorOwner() == None
                    CloseFood[iNearbyFoods].Activate(kCompanion, true)
                    ;kCompanion.AddItem(CloseFood[iNearbyFoods].GetBaseObject(), 1, true)
                    int handle = ModEvent.create("Winterweight_ItemConsume")
                    ModEvent.pushForm(handle, kCompanion as Form)
                    ModEvent.pushForm(handle, CloseFood[iNearbyFoods].GetBaseObject())
                    ModEvent.pushInt(handle, 1)
                    ModEvent.Send(handle)
                    kCompanion.EquipItem(CloseFood[iNearbyFoods].GetBaseObject())
                    CloseFood[iNearbyFoods].Disable()
                    CloseFood[iNearbyFoods].Delete()
                EndIf
                iNearbyFoods -= 1
            EndWhile
        EndIf
    EndIf
    Self.Stop()
EndEvent