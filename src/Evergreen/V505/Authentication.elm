module Evergreen.V505.Authentication exposing (..)

import Dict
import Evergreen.V505.Credentials
import Evergreen.V505.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V505.User.User
    , credentials : Evergreen.V505.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
