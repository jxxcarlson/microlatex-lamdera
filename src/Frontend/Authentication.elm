module Frontend.Authentication exposing (setSignupState)

import Effect.Command exposing (Command, FrontendOnly)
import Types


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
