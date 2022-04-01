module Evergreen.V205.Authentication exposing (..)

import Dict
import Evergreen.V205.Credentials
import Evergreen.V205.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V205.User.User
    , credentials : Evergreen.V205.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
