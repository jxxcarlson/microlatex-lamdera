module Evergreen.V260.Authentication exposing (..)

import Dict
import Evergreen.V260.Credentials
import Evergreen.V260.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V260.User.User
    , credentials : Evergreen.V260.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
