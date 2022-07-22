module Frontend.Authentication exposing
    ( setSignupState
    , userSignedUp
    )

import Effect.Command exposing (Command, FrontendOnly)
import Types exposing (MaximizedIndex(..), TagSelection(..))


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
