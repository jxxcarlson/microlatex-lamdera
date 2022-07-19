module Evergreen.V710.Authentication exposing (..)

import Dict
import Evergreen.V710.Credentials
import Evergreen.V710.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V710.User.User
    , credentials : Evergreen.V710.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
