module Backend.Collaboration exposing (initializeNetworkModelsWithDocument, resetNetworkModelForDocument)

import CollaborativeEditing.NetworkModel as NetworkModel
import Dict
import Effect.Command as Command
import Effect.Lamdera exposing (ClientId)
import Maybe.Extra
import Share
import Types exposing (ToFrontend(..))


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
