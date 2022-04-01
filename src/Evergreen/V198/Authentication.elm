module Evergreen.V198.Authentication exposing (..)

import Dict
import Evergreen.V198.Credentials
import Evergreen.V198.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V198.User.User
    , credentials : Evergreen.V198.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
