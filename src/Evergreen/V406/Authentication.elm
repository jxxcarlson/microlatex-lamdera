module Evergreen.V406.Authentication exposing (..)

import Dict
import Evergreen.V406.Credentials
import Evergreen.V406.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V406.User.User
    , credentials : Evergreen.V406.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
