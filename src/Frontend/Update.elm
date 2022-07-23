port module Frontend.Update exposing
    ( adjustId
    , changeLanguage
    , changeSlug
    , firstSyncLR
    , handleUrlRequest
    , hardDeleteDocument
    , inputTitle
    , newDocument
    , newFolder
    , nextSyncLR
    , playSound
    , playSound_
    , render
    , runSpecial
    , saveCurrentDocumentToBackend
    , searchText
    , setLanguage
    , setPublic
    , setPublicDocumentAsCurrentById
    , setUserLanguage
    , setViewportForElement
    , softDeleteDocument
    , syncLR
    , undeleteDocument
    , updateKeys
    , updateWithViewport
    )

--

import Browser
import CollaborativeEditing.NetworkModel as NetworkModel
import Compiler.ASTTools
import Compiler.DifferentialParser
import Config
import Docs
import Document exposing (Document)
import Duration
import Effect.Browser.Dom
import Effect.Browser.Navigation
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera exposing (sendToBackend)
import Effect.Process
import Effect.Task
import ExtractInfo
import Frontend.Document
import Json.Encode
import Keyboard
import List.Extra
import Parser.Language exposing (Language(..))
import Render.Msg exposing (Handling(..), MarkupMsg(..), SolutionState(..))
import Types exposing (DocumentDeleteState(..), FrontendModel, FrontendMsg(..), MessageStatus(..), PopupState(..), ToBackend(..))
import User exposing (User)
import View.Utility


port playSound : Json.Encode.Value -> Cmd msg


{-| Expose this and use it instead of the port directly
-}
playSound_ : String -> Command FrontendOnly toMsg msg
playSound_ soundName =
    Command.sendToJs "playSound" playSound (Json.Encode.string soundName)



-- port playSound : String -> Command FrontendOnly ToBackend FrontendMsg
{-
         --- CONTENTS

   --- SIGN UP, SIGN IN, SIGN OUT
   --- EDITOR
   --- EXPORT
   --- DOCUMENT
   ---    Save
   ---    Set params
   ---    Post process
   ---    setDocumentAsCurrent
   ---    handleCurrentDocumentChange
   ---    Included files
   ---    updateDoc
   ---    handle document
   ---    savePreviousCurrentDocumentCmd
   ---    delete
   --- SEARCH
   --- INPUT
   --- DEBOUNCE
   --- RENDER
   --- SET PARAM
   --- SYNC
   --- VIEWPORT
   --- SPECIAL
   --- URL HANDLING
   --- KEYBOARD COMMANDS
   --- UTILITY


-}
--- SIGN UP, SIGN IN, SIGN OUT
--- EDITOR
--- EXPORT
--- DOCUMENT


newFolder : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
newFolder model =
    let
        folderDocument =
            ExtractInfo.makeFolder model.currentTime (model.currentUser |> Maybe.map .username |> Maybe.withDefault "anon") model.inputFolderName model.inputFolderTag

        documentsCreatedCounter =
            model.documentsCreatedCounter + 1

        editRecord =
            Compiler.DifferentialParser.init model.includedContent folderDocument.language folderDocument.content
    in
    ( { model
        | showEditor = False
        , inputTitle = ""
        , title = Compiler.ASTTools.title editRecord.parsed
        , documentsCreatedCounter = documentsCreatedCounter
        , popupState = NoPopup
      }
    , Command.batch [ Effect.Lamdera.sendToBackend (CreateDocument model.currentUser folderDocument) ]
    )


newDocument : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
newDocument model =
    let
        emptyDoc =
            Document.empty

        documentsCreatedCounter =
            model.documentsCreatedCounter + 1

        titleString =
            if String.length model.inputTitle < 3 then
                "??"

            else
                model.inputTitle

        title =
            case model.language of
                MicroLaTeXLang ->
                    "\\title{" ++ titleString ++ "}\n\n"

                _ ->
                    "| title\n" ++ titleString ++ "\n\n"

        doc =
            { emptyDoc
                | title = titleString
                , content = title
                , author = Maybe.map .username model.currentUser
                , language = model.language
            }
                |> Document.addSlug
    in
    ( { model
        | inputTitle = ""
        , counter = model.counter + 1
        , documentsCreatedCounter = documentsCreatedCounter
        , popupState = NoPopup
      }
        |> Frontend.Document.postProcessDocument doc
    , Command.batch [ Effect.Lamdera.sendToBackend (CreateDocument model.currentUser doc) ]
    )



---    Save


saveCurrentDocumentToBackend : Maybe Document.Document -> Maybe User -> Command FrontendOnly ToBackend FrontendMsg
saveCurrentDocumentToBackend mDoc mUser =
    case mDoc of
        Nothing ->
            Command.none

        Just doc ->
            case doc.status of
                Document.DSSoftDelete ->
                    Command.none

                Document.DSReadOnly ->
                    Command.none

                Document.DSCanEdit ->
                    Effect.Lamdera.sendToBackend (SaveDocument mUser doc)



---    Set params


setPublic : FrontendModel -> Document -> Bool -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setPublic model doc public =
    let
        newDocument_ =
            { doc | public = public }

        documents =
            List.Extra.setIf (\d -> d.id == newDocument_.id) newDocument_ model.documents
    in
    ( { model | documents = documents, documentDirty = False, currentDocument = Just newDocument_, inputTitle = "" }, Effect.Lamdera.sendToBackend (SaveDocument model.currentUser newDocument_) )


setPublicDocumentAsCurrentById : FrontendModel -> String -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setPublicDocumentAsCurrentById model id =
    case List.filter (\doc -> doc.id == id) model.publicDocuments |> List.head of
        Nothing ->
            ( { model | messages = [ { txt = "No document of id [" ++ id ++ "] found", status = MSWhite } ] }, Command.none )

        Just doc ->
            let
                newEditRecord =
                    Compiler.DifferentialParser.init model.includedContent doc.language doc.content
            in
            ( { model
                | currentDocument = Just doc
                , networkModel = NetworkModel.init (NetworkModel.initialServerState doc.id (User.currentUserId model.currentUser) doc.content)
                , sourceText = doc.content
                , initialText = doc.content
                , editRecord = newEditRecord
                , title = Compiler.ASTTools.title newEditRecord.parsed
                , tableOfContents = Compiler.ASTTools.tableOfContents newEditRecord.parsed
                , messages = [ { txt = "id = " ++ doc.id, status = MSWhite } ]
                , counter = model.counter + 1
              }
            , Command.batch [ View.Utility.setViewPortToTop model.popupState ]
            )



---    Post process
---    setDocumentAsCurrent
---    handleCurrentDocumentChange
---    Included files
---    updateDoc


changeSlug : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
changeSlug model =
    case model.currentDocument of
        Nothing ->
            ( model, Command.none )

        Just doc ->
            let
                newDocument_ =
                    Document.changeSlug doc
            in
            ( { model | currentDocument = Just newDocument_ } |> Frontend.Document.postProcessDocument newDocument_
            , sendToBackend (SaveDocument model.currentUser newDocument_)
            )



---    handle document
-- TODO: B
---    savePreviousCurrentDocumentCmd
---    delete


undeleteDocument : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
undeleteDocument model =
    case model.currentDocument of
        Nothing ->
            ( model, Command.none )

        Just doc ->
            let
                updatedUser : Maybe User
                updatedUser =
                    case model.currentUser of
                        Nothing ->
                            Nothing

                        Just user ->
                            Just user

                -- deleteDocFromCurrentUser model doc
                ( newDoc, currentDocument, newDocuments ) =
                    let
                        newDoc_ =
                            { doc | status = Document.DSCanEdit } |> Document.removeTag "folder:deleted"
                    in
                    ( newDoc_, Just Docs.deleted, newDoc_ :: List.filter (\doc_ -> doc_.id /= doc.id) model.documents )
            in
            ( { model
                | currentDocument = currentDocument
                , documents = newDocuments
                , documentDirty = False
                , deleteDocumentState = WaitingForDeleteAction
                , currentUser = updatedUser
              }
                |> Frontend.Document.postProcessDocument newDoc
            , Command.batch
                [ Effect.Lamdera.sendToBackend (SaveDocument model.currentUser newDoc)

                --, Effect.Process.sleep (Duration.milliseconds 500) |> Effect.Task.perform (always (SetPublicDocumentAsCurrentById Config.documentDeletedNotice))
                ]
            )


softDeleteDocument : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
softDeleteDocument model =
    case model.currentDocument of
        Nothing ->
            ( model, Command.none )

        Just doc ->
            let
                updatedUser =
                    case model.currentUser of
                        Nothing ->
                            Nothing

                        Just _ ->
                            Frontend.Document.deleteDocFromCurrentUser model doc

                ( newDoc, currentDocument, newDocuments ) =
                    ( { doc | status = Document.DSSoftDelete } |> Document.addTag "folder:deleted", Just Docs.deleted, List.filter (\d -> d.id /= doc.id) model.documents )
            in
            ( { model
                | currentDocument = currentDocument
                , documents = newDocuments
                , documentDirty = False
                , deleteDocumentState = WaitingForDeleteAction
                , currentUser = updatedUser
              }
                |> Frontend.Document.postProcessDocument Docs.deleted
            , Command.batch
                [ Effect.Lamdera.sendToBackend (SaveDocument model.currentUser newDoc)
                ]
            )


hardDeleteDocument : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
hardDeleteDocument model =
    case model.currentDocument of
        Nothing ->
            ( model, Command.none )

        Just doc ->
            let
                newUser =
                    case model.currentUser of
                        Nothing ->
                            Nothing

                        Just _ ->
                            Frontend.Document.deleteDocFromCurrentUser model doc

                newMasterDocument =
                    case model.currentMasterDocument of
                        Nothing ->
                            Nothing

                        Just masterDoc ->
                            let
                                newContent =
                                    masterDoc.content
                                        |> String.lines
                                        |> List.filter (\line -> not (String.contains doc.title line || String.contains doc.id line))
                                        |> String.join "\n"
                            in
                            Just { masterDoc | content = newContent }
            in
            ( { model
                | currentDocument = Just Docs.deleted
                , currentMasterDocument = newMasterDocument
                , documents = List.filter (\d -> d.id /= doc.id) model.documents
                , hardDeleteDocumentState = Types.WaitingForHardDeleteAction
                , currentUser = newUser
              }
                |> Frontend.Document.postProcessDocument Docs.deleted
            , Command.batch [ Effect.Lamdera.sendToBackend (HardDeleteDocumentBE doc), Effect.Process.sleep (Duration.milliseconds 500) |> Effect.Task.perform (always (SetPublicDocumentAsCurrentById Config.documentDeletedNotice)) ]
            )



--- SEARCH


searchText : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
searchText model =
    let
        ids =
            Compiler.ASTTools.matchingIdsInAST model.searchSourceText model.editRecord.parsed

        ( cmd, id ) =
            case List.head ids of
                Nothing ->
                    ( Command.none, "(none)" )

                Just id_ ->
                    ( View.Utility.setViewportForElement (View.Utility.viewId model.popupState) id_, id_ )
    in
    ( { model | selectedId = id, searchCount = model.searchCount + 1, messages = [ { txt = "ids: " ++ String.join ", " ids, status = MSWhite } ] }, cmd )



--- INPUT


inputTitle : FrontendModel -> String -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
inputTitle model str =
    ( { model | inputTitle = str }, Command.none )



-- INPUT FROM THE CODEMIRROR EDITOR (CHANGES IN CURSOR, TEXT)
--- DEBOUNCE
--- RENDER


render : FrontendModel -> MarkupMsg -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
render model msg_ =
    case msg_ of
        Render.Msg.SendMeta _ ->
            -- ( { model | lineNumber = m.loc.begin.row, message = "line " ++ String.fromInt (m.loc.begin.row + 1) }, Cmd.none )
            ( model, Command.none )

        Render.Msg.SendId line ->
            -- TODO: the below (using id also for line number) is not a great idea.
            ( { model | messages = [ { txt = "Line " ++ (line |> String.toInt |> Maybe.withDefault 0 |> (\x -> x + 1) |> String.fromInt), status = MSYellow } ], linenumber = String.toInt line |> Maybe.withDefault 0 }, Command.none )

        Render.Msg.SelectId id ->
            -- the element with this id will be highlighted
            ( { model | selectedId = id }, View.Utility.setViewportForElement (View.Utility.viewId model.popupState) id )

        GetPublicDocument docHandling id ->
            case docHandling of
                MHStandard ->
                    ( { model | messages = { txt = "Fetch (1): " ++ id, status = MSGreen } :: [] }
                    , Effect.Lamdera.sendToBackend (FetchDocumentById Types.StandardHandling id)
                    )

                MHAsCheatSheet ->
                    ( { model | messages = { txt = "Fetch (2): " ++ id, status = MSGreen } :: [] }
                    , Effect.Lamdera.sendToBackend (FetchDocumentById Types.HandleAsManual id)
                    )

        GetPublicDocumentFromAuthor handling authorName searchKey ->
            case handling of
                MHStandard ->
                    ( model, Effect.Lamdera.sendToBackend (FindDocumentByAuthorAndKey Types.StandardHandling authorName searchKey) )

                MHAsCheatSheet ->
                    ( model, Effect.Lamdera.sendToBackend (FindDocumentByAuthorAndKey Types.HandleAsManual authorName searchKey) )

        ProposeSolution proposal ->
            case proposal of
                Solved id ->
                    ( { model | selectedId = id }, Command.none )

                Unsolved ->
                    ( { model | selectedId = "???" }, Command.none )



--- SET PARAM


setLanguage : Bool -> Language -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setLanguage dismiss lang model =
    if dismiss then
        ( { model | language = lang, popupState = NoPopup }, Command.none )
            |> (\( m, _ ) -> changeLanguage m)

    else
        ( { model | language = lang }, Command.none )


changeLanguage : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
changeLanguage model =
    case model.currentDocument of
        Nothing ->
            ( model, Command.none )

        Just doc ->
            let
                newDoc =
                    { doc | language = model.language }
            in
            ( { model | documentDirty = False }
            , Effect.Lamdera.sendToBackend (SaveDocument model.currentUser newDoc)
            )
                |> (\( m, c ) -> ( Frontend.Document.postProcessDocument newDoc m, c ))


setUserLanguage : Language -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setUserLanguage lang model =
    ( { model | inputLanguage = lang, popupState = NoPopup }, Command.none )



--- SYNC


firstSyncLR : FrontendModel -> String -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
firstSyncLR model searchSourceText =
    let
        data =
            let
                foundIds_ =
                    Compiler.ASTTools.matchingIdsInAST searchSourceText model.editRecord.parsed

                id_ =
                    List.head foundIds_ |> Maybe.withDefault "(nothing)"
            in
            { foundIds = foundIds_
            , foundIdIndex = 1
            , cmd = View.Utility.setViewportForElement (View.Utility.viewId model.popupState) id_
            , selectedId = id_
            , searchCount = 0
            }
    in
    ( { model
        | selectedId = data.selectedId
        , foundIds = data.foundIds
        , foundIdIndex = data.foundIdIndex
        , searchCount = data.searchCount
        , messages = [ { txt = ("[" ++ adjustId data.selectedId ++ "]") :: List.map adjustId data.foundIds |> String.join ", ", status = MSWhite } ]
      }
    , data.cmd
    )


nextSyncLR : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
nextSyncLR model =
    let
        id_ =
            List.Extra.getAt model.foundIdIndex model.foundIds |> Maybe.withDefault "(nothing)"
    in
    ( { model
        | selectedId = id_
        , foundIdIndex = modBy (List.length model.foundIds) (model.foundIdIndex + 1)
        , searchCount = model.searchCount + 1
        , messages = [ { txt = ("[" ++ adjustId id_ ++ "]") :: List.map adjustId model.foundIds |> String.join ", ", status = MSWhite } ]
      }
    , View.Utility.setViewportForElement (View.Utility.viewId model.popupState) id_
    )


syncLR : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
syncLR model =
    let
        data =
            if model.foundIdIndex == 0 then
                let
                    foundIds_ =
                        Compiler.ASTTools.matchingIdsInAST model.searchSourceText model.editRecord.parsed

                    id_ =
                        List.head foundIds_ |> Maybe.withDefault "(nothing)"
                in
                { foundIds = foundIds_
                , foundIdIndex = 1
                , cmd = View.Utility.setViewportForElement (View.Utility.viewId model.popupState) id_
                , selectedId = id_
                , searchCount = 0
                }

            else
                let
                    id_ =
                        List.Extra.getAt model.foundIdIndex model.foundIds |> Maybe.withDefault "(nothing)"
                in
                { foundIds = model.foundIds
                , foundIdIndex = modBy (List.length model.foundIds) (model.foundIdIndex + 1)
                , cmd = View.Utility.setViewportForElement (View.Utility.viewId model.popupState) id_
                , selectedId = id_
                , searchCount = model.searchCount + 1
                }
    in
    ( { model
        | selectedId = data.selectedId
        , foundIds = data.foundIds
        , foundIdIndex = data.foundIdIndex
        , searchCount = data.searchCount
        , messages = [ { txt = ("!![" ++ adjustId data.selectedId ++ "]") :: List.map adjustId data.foundIds |> String.join ", ", status = MSWhite } ]
      }
    , data.cmd
    )



--- VIEWPORT


setViewportForElement : FrontendModel -> Result xx ( Effect.Browser.Dom.Element, Effect.Browser.Dom.Viewport ) -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setViewportForElement model result =
    case result of
        Ok ( element, viewport ) ->
            ( { model | messages = [] }
              -- [ { txt = model.message ++ ", setting viewport", status = MSNormal } ] }
            , View.Utility.setViewPortForSelectedLine model.popupState element viewport
            )

        Err _ ->
            -- TODO: restore error message
            -- ( { model | message = model.message ++ ", could not set viewport" }, Cmd.none )
            ( model, Command.none )


updateWithViewport : Effect.Browser.Dom.Viewport -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateWithViewport vp model =
    let
        w =
            round vp.viewport.width

        h =
            round vp.viewport.height
    in
    ( { model
        | windowWidth = w
        , windowHeight = h
      }
    , Command.none
    )



-- LOCKING AND UNLOCKING DOCUMENTS
--- SPECIAL


runSpecial : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
runSpecial model =
    case model.currentUser of
        Nothing ->
            ( model, Command.none )

        Just user ->
            if user.username == "jxxcarlson" then
                ( model, Effect.Lamdera.sendToBackend (ApplySpecial user model.inputSpecial) )

            else
                ( model, Command.none )



--- URL HANDLING


handleUrlRequest model urlRequest =
    case urlRequest of
        Browser.Internal url ->
            let
                cmd =
                    case .fragment url of
                        Just internalId ->
                            -- internalId is the part after '#', if present
                            View.Utility.setViewportForElement (View.Utility.viewId model.popupState) internalId

                        Nothing ->
                            --if String.left 3 url.path == "/a/" then
                            Effect.Lamdera.sendToBackend (SearchForDocumentsWithAuthorAndKey (String.dropLeft 3 url.path))

                --
                --else if String.left 3 url.path == "/p/" then
                --    sendToBackend (GetDocumentByPublicId (String.dropLeft 3 url.path))
                --
                --else
                --    Nav.pushUrl model.key (Url.toString url)
            in
            ( model, cmd )

        Browser.External url ->
            ( model
            , Effect.Browser.Navigation.load url
            )



--- KEYBOARD COMMANDS


{-| ctrl-S: Left-to-Right sync
-}
updateKeys model keyMsg =
    let
        pressedKeys =
            Keyboard.update keyMsg model.pressedKeys

        doSync =
            if List.member Keyboard.Control pressedKeys && List.member (Keyboard.Character "S") pressedKeys then
                not model.doSync

            else
                model.doSync
    in
    ( { model | pressedKeys = pressedKeys, doSync = doSync, lastInteractionTime = model.currentTime }
    , Command.none
    )



--- UTILITY


adjustId : String -> String
adjustId str =
    case String.toInt str of
        Nothing ->
            str

        Just n ->
            String.fromInt (n + 2)
