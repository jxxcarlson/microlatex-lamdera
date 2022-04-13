module Network exposing (..)

import AbstractNetwork
import Diff
import Diff.Change
import List.Extra


type alias NetworkModel =
    AbstractNetwork.NetworkModel NetworkMessage Model


type alias Model =
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



--
--localState_ : (NetworkMessage -> Model -> Model) -> NetworkModel -> Model
--localState_ updateFunc_ localModel =
--    List.foldl updateFunc_ localModel.serverState localModel.localMsgs


updateFunc : NetworkMessage -> Model -> Model
updateFunc =
    Diff.Change.reconcileList


localState : NetworkModel -> Model
localState localModel =
    List.foldl updateFunc localModel.serverState localModel.localMsgs


updateFromBackend : NetworkMessage -> NetworkModel -> NetworkModel
updateFromBackend msg localModel =
    { localMsgs = List.Extra.remove msg localModel.localMsgs
    , serverState = updateFunc msg localModel.serverState
    }
