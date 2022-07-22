module Frontend.Authentication exposing
    ( setSignupState
    , signIn
    , signOut
    , signUp
    , userSignedUp
    )

import Authentication
import Config
import Docs
import Effect.Browser.Navigation
import Effect.Command exposing (Command, FrontendOnly)
import Effect.Lamdera
import Effect.Time
import Types
    exposing
        ( DocumentList(..)
        , FrontendModel
        , FrontendMsg
        , MaximizedIndex(..)
        , MessageStatus(..)
        , TagSelection(..)
        , ToBackend
        )


signOut : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
signOut model =
    let
        cmd =
            case model.currentUser of
                Nothing ->
                    Effect.Command.none

                Just user ->
                    Effect.Lamdera.sendToBackend (Types.UpdateUserWith user)
    in
    ( { model
        | currentUser = Nothing
        , activeEditor = Nothing
        , clientIds = []
        , currentDocument = Just Docs.simpleWelcomeDoc
        , currentMasterDocument = Nothing
        , documents = []
        , messages = [ { txt = "Signed out", status = MSWhite } ]
        , inputSearchKey = ""
        , actualSearchKey = ""
        , inputTitle = ""
        , chatMessages = []
        , tagSelection = Types.TagPublic
        , inputUsername = ""
        , inputPassword = ""
        , documentList = StandardList
        , maximizedIndex = Types.MPublicDocs
        , popupState = Types.NoPopup
        , showEditor = False
        , chatVisible = False
        , sortMode = Types.SortByMostRecent
        , lastInteractionTime = Effect.Time.millisToPosix 0
      }
    , Effect.Command.batch
        [ Effect.Browser.Navigation.pushUrl model.key "/"
        , cmd
        , Effect.Lamdera.sendToBackend (Types.SignOutBE (model.currentUser |> Maybe.map .username))
        , Effect.Lamdera.sendToBackend (Types.GetDocumentById Types.StandardHandling Config.welcomeDocId)
        , Effect.Lamdera.sendToBackend (Types.GetPublicDocuments Types.SortByMostRecent Nothing)
        ]
    )



-- |> join (unshare (User.currentUsername model.currentUser))
-- narrowCast : Username -> Document.Document -> Types.ConnectionDict -> Cmd Types.BackendMsg
--     , Cmd.batch (narrowCastDocs model username documents)


signIn : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
signIn model =
    if String.length model.inputPassword >= 8 then
        case Config.defaultUrl of
            Nothing ->
                ( { model | timer = 0, inputPassword = "", showSignInTimer = True }, Effect.Lamdera.sendToBackend (Types.SignInBE model.inputUsername (Authentication.encryptForTransit model.inputPassword)) )

            Just url ->
                ( { model | timer = 0, inputPassword = "", showSignInTimer = True, url = url }, Effect.Lamdera.sendToBackend (Types.SignInBE model.inputUsername (Authentication.encryptForTransit model.inputPassword)) )

    else
        ( { model | inputPassword = "", showSignInTimer = True, messages = [ { txt = "Password must be at least 8 letters long.", status = MSYellow } ] }, Effect.Command.none )


signUp : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
signUp model =
    let
        errors =
            []
                |> reject (String.length model.inputSignupUsername < 3) "username: at least three letters"
                |> reject (String.toLower model.inputSignupUsername /= model.inputSignupUsername) "username: all lower case characters"
                |> reject (model.inputPassword == "") "password: cannot be empty"
                |> reject (String.length model.inputPassword < 8) "password: at least 8 letters long."
                |> reject (model.inputPassword /= model.inputPasswordAgain) "passwords do not match"
                |> reject (model.inputEmail == "") "missing email address"
                |> reject (model.inputRealname == "") "missing real name"
    in
    if List.isEmpty errors then
        ( model
        , Effect.Lamdera.sendToBackend (Types.SignUpBE model.inputSignupUsername model.inputLanguage (Authentication.encryptForTransit model.inputPassword) model.inputRealname model.inputEmail)
        )

    else
        ( { model | messages = [ { txt = String.join "; " errors, status = MSYellow } ] }, Effect.Command.none )


reject : Bool -> String -> List String -> List String
reject condition message messages =
    if condition then
        message :: messages

    else
        messages


setSignupState : Types.FrontendModel -> Types.SignupState -> ( Types.FrontendModel, Command FrontendOnly Types.ToBackend Types.FrontendMsg )
setSignupState model state =
    ( { model
        | signupState = state
        , inputSignupUsername = ""
        , inputPassword = ""
        , inputPasswordAgain = ""
        , inputEmail = ""
        , inputRealname = ""
        , messages = []
      }
    , Effect.Command.none
    )


userSignedUp model user clientId =
    ( { model
        | signupState = Types.HideSignUpForm
        , currentUser = Just user
        , clientIds = clientId :: model.clientIds
        , maximizedIndex = MMyDocs
        , inputRealname = ""
        , inputEmail = ""
        , inputUsername = ""
        , tagSelection = TagUser
        , inputPassword = ""
        , inputPasswordAgain = ""
        , language = user.preferences.language
        , timeSignedIn = model.currentTime
        , showSignInTimer = False
      }
      -- , Effect.Lamdera.sendToBackend (GetDocumentById Types.StandardHandling Config.newsDocId)
    , Effect.Command.none
    )
