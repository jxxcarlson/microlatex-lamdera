module Frontend.Update exposing
    ( handleSignIn
    , handleSignOut
    , handleUrlRequest
    , newDocument
    , runSpecial
    , setDocumentAsCurrent
    , setDocumentInPhoneAsCurrent
    , setViewportForElement
    , updateCurrentDocument
    , updateKeys
    , updateWithViewport
    )

--

import Authentication
import Backend.Backup
import Browser exposing (UrlRequest(..))
import Browser.Events
import Browser.Navigation as Nav
import Cmd.Extra exposing (withCmd, withNoCmd)
import Compiler.ASTTools
import Compiler.Acc
import Compiler.DifferentialParser
import Config
import Debounce
import Docs
import Document exposing (Document)
import Element
import File
import File.Download as Download
import File.Select as Select
import Frontend.Cmd
import Frontend.PDF as PDF
import Html
import Keyboard
import Lamdera exposing (sendToBackend)
import List.Extra
import Markup
import Parser.Language exposing (Language(..))
import Process
import Render.LaTeX as LaTeX
import Render.Markup as L0
import Render.Msg exposing (MarkupMsg(..))
import Render.Settings as Settings
import Task
import Types exposing (..)
import Url exposing (Url)
import UrlManager
import Util
import View.Data
import View.Main
import View.Phone
import View.Utility


setViewportForElement model result =
    case result of
        Ok ( element, viewport ) ->
            ( { model | message = model.message ++ ", setting viewport" }, View.Utility.setViewPortForSelectedLine element viewport )

        Err _ ->
            -- TODO: restore error message
            -- ( { model | message = model.message ++ ", could not set viewport" }, Cmd.none )
            ( model, Cmd.none )


setDocumentAsCurrent model doc permissions =
    let
        newEditRecord =
            Compiler.DifferentialParser.init doc.language doc.content
    in
    ( { model
        | currentDocument = Just doc
        , sourceText = doc.content
        , initialText = doc.content
        , editRecord = newEditRecord
        , title =
            Compiler.ASTTools.title model.language newEditRecord.parsed
        , tableOfContents = Compiler.ASTTools.tableOfContents newEditRecord.parsed
        , message = "id = " ++ doc.id
        , permissions = setPermissions model.currentUser permissions doc
        , counter = model.counter + 1
        , language = doc.language
      }
    , Cmd.batch [ View.Utility.setViewPortToTop ]
    )


setPermissions currentUser permissions document =
    case document.author of
        Nothing ->
            permissions

        Just author ->
            if Just author == Maybe.map .username currentUser then
                CanEdit

            else
                permissions


setDocumentInPhoneAsCurrent model doc permissions =
    let
        ast =
            Markup.parse doc.language doc.content |> Compiler.Acc.transformST doc.language
    in
    ( { model
        | currentDocument = Just doc
        , sourceText = doc.content
        , initialText = doc.content
        , title = Compiler.ASTTools.title model.language ast
        , tableOfContents = Compiler.ASTTools.tableOfContents ast
        , message = "id = " ++ doc.id
        , permissions = setPermissions model.currentUser permissions doc
        , counter = model.counter + 1
        , phoneMode = PMShowDocument
      }
    , View.Utility.setViewPortToTop
    )


runSpecial model =
    case model.currentUser of
        Nothing ->
            model |> withNoCmd

        Just user ->
            if user.username == "jxxcarlson" then
                model |> withCmd (sendToBackend (ApplySpecial user model.inputSpecial))

            else
                model |> withNoCmd


handleSignOut model =
    ( { model
        | currentUser = Nothing
        , currentDocument = Just Docs.notSignedIn
        , documents = []
        , message = "Signed out"
        , inputSearchKey = ""
        , inputUsername = ""
        , inputPassword = ""
        , showEditor = False
      }
    , -- Cmd.none
      Nav.pushUrl model.key "/"
    )


handleSignIn model =
    if String.length model.inputPassword >= 8 then
        ( model
        , sendToBackend (SignInOrSignUp model.inputUsername (Authentication.encryptForTransit model.inputPassword))
        )

    else
        ( { model | message = "Password must be at least 8 letters long." }, Cmd.none )


handleUrlRequest model urlRequest =
    case urlRequest of
        Internal url ->
            let
                cmd =
                    case .fragment url of
                        Just internalId ->
                            -- internalId is the part after '#', if present
                            View.Utility.setViewportForElement internalId

                        Nothing ->
                            --if String.left 3 url.path == "/a/" then
                            sendToBackend (GetDocumentByAuthorId (String.dropLeft 3 url.path))

                --
                --else if String.left 3 url.path == "/p/" then
                --    sendToBackend (GetDocumentByPublicId (String.dropLeft 3 url.path))
                --
                --else
                --    Nav.pushUrl model.key (Url.toString url)
            in
            ( model, cmd )

        External url ->
            ( model
            , Nav.load url
            )


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
    ( { model | pressedKeys = pressedKeys, doSync = doSync }
    , Cmd.none
    )


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
    , Cmd.none
    )


newDocument model =
    let
        emptyDoc =
            Document.empty

        documentsCreatedCounter =
            model.documentsCreatedCounter + 1

        title =
            "New Document (" ++ String.fromInt documentsCreatedCounter ++ ")"

        titleString =
            case model.language of
                L0Lang ->
                    "| title\n" ++ title ++ "\n\n"

                MicroLaTeXLang ->
                    "\\title{" ++ title ++ "}\n\n"

        doc =
            { emptyDoc
                | title = title
                , content = titleString
                , author = Maybe.map .username model.currentUser
                , language = model.language
            }
    in
    ( { model | showEditor = True, documentsCreatedCounter = documentsCreatedCounter }
    , Cmd.batch [ sendToBackend (CreateDocument model.currentUser doc) ]
    )


updateCurrentDocument : Document -> FrontendModel -> FrontendModel
updateCurrentDocument doc model =
    { model | currentDocument = Just doc }
