module Backend.Collaboration exposing
    ( getConnectedUsers
    , getConnectionData
    , initializeNetworkModelsWithDocument
    , resetNetworkModelForDocument
    )

import CollaborativeEditing.NetworkModel as NetworkModel
import Dict
import Effect.Command as Command
import Effect.Lamdera exposing (ClientId)
import Maybe.Extra
import Share
import Types exposing (BackendModel, ToFrontend(..))


initializeNetworkModelsWithDocument model doc =
    let
        currentEditorList =
            doc.currentEditorList

        userIds =
            List.map .userId currentEditorList

        clients : List ClientId
        clients =
            List.foldl (\editorName acc -> Dict.get editorName model.connectionDict :: acc) [] (List.map .username currentEditorList)
                |> Maybe.Extra.values
                |> List.concat
                |> List.map .client

        networkModel =
            NetworkModel.initWithUsersAndContent doc.id userIds doc.content

        sharedDocument_ =
            Share.toSharedDocument doc

        sharedDocument : Types.SharedDocument
        sharedDocument =
            { sharedDocument_ | currentEditors = doc.currentEditorList }

        sharedDocumentDict =
            Dict.insert doc.id sharedDocument model.sharedDocumentDict

        cmds =
            List.map (\clientId_ -> Effect.Lamdera.sendToFrontend clientId_ (InitializeNetworkModel networkModel)) clients
    in
    ( { model | sharedDocumentDict = sharedDocumentDict }, Command.batch cmds )


resetNetworkModelForDocument model doc =
    let
        currentEditorList =
            doc.currentEditorList

        document =
            { doc | currentEditorList = [] }

        clients : List ClientId
        clients =
            List.foldl (\editorName acc -> Dict.get editorName model.connectionDict :: acc) [] (List.map .username currentEditorList)
                |> Maybe.Extra.values
                |> List.concat
                |> List.map .client

        networkModel =
            NetworkModel.initWithUsersAndContent "--fake--" [] ""

        cmds =
            List.map (\clientId_ -> Effect.Lamdera.sendToFrontend clientId_ (ResetNetworkModel networkModel document)) clients
    in
    ( model, Command.batch cmds )


getConnectionData : BackendModel -> List String
getConnectionData model =
    model.connectionDict
        |> Dict.toList
        |> List.map (\( u, data ) -> u ++ ":: " ++ String.fromInt (List.length data) ++ " :: " ++ connectionDataListToString data)


{-| Return user names of connected users
-}
getConnectedUsers : BackendModel -> List String
getConnectedUsers model =
    Dict.keys model.connectionDict


truncateMiddle : Int -> Int -> String -> String
truncateMiddle dropBoth dropRight str =
    String.left dropBoth str ++ "..." ++ String.right dropBoth (String.dropRight dropRight str)


connectionDataListToString : List Types.ConnectionData -> String
connectionDataListToString list =
    list |> List.map connectionDataToString |> String.join "; "


connectionDataToString : Types.ConnectionData -> String
connectionDataToString { session, client } =
    "(" ++ truncateMiddle 2 0 (Effect.Lamdera.sessionIdToString session) ++ ", " ++ truncateMiddle 2 2 (Effect.Lamdera.clientIdToString client) ++ ")"
