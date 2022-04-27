module Evergreen.V502.Authentication exposing (..)

import Dict
import Evergreen.V502.Credentials
import Evergreen.V502.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V502.User.User
    , credentials : Evergreen.V502.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
