module Network exposing (NetworkModel, init, localState, updateFromBackend, updateFromUser)

import AbstractNetwork
import Diff
import Diff.Change
import List.Extra


type alias NetworkModel =
    AbstractNetwork.NetworkModel NetworkMessage Data

generateDiffMessage : String -> String -> NetworkMessage
generateDiffMessage oldString newString =


type alias Data =
    List String


type alias NetworkMessage =
    List (List (Diff.Change String))


init : List String -> NetworkModel
init =
    AbstractNetwork.init


updateFromUser : NetworkMessage -> NetworkModel -> NetworkModel
updateFromUser msg localModel =
    { localMsgs = localModel.localMsgs ++ [ msg ]
    , serverState = localModel.serverState
    }


updateFunc : NetworkMessage -> Data -> Data
updateFunc =
    Diff.Change.reconcileList


localState : NetworkModel -> Data
localState localModel =
    List.foldl updateFunc localModel.serverState localModel.localMsgs


updateFromBackend : NetworkMessage -> NetworkModel -> NetworkModel
updateFromBackend msg localModel =
    { localMsgs = List.Extra.remove msg localModel.localMsgs
    , serverState = updateFunc msg localModel.serverState
    }
