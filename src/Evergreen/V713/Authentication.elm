module Evergreen.V713.Authentication exposing (..)

import Dict
import Evergreen.V713.Credentials
import Evergreen.V713.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V713.User.User
    , credentials : Evergreen.V713.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
