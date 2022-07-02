module Evergreen.V685.Authentication exposing (..)

import Dict
import Evergreen.V685.Credentials
import Evergreen.V685.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V685.User.User
    , credentials : Evergreen.V685.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
