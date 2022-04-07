module Evergreen.V280.Authentication exposing (..)

import Dict
import Evergreen.V280.Credentials
import Evergreen.V280.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V280.User.User
    , credentials : Evergreen.V280.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
