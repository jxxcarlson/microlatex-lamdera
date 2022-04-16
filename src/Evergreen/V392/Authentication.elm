module Evergreen.V392.Authentication exposing (..)

import Dict
import Evergreen.V392.Credentials
import Evergreen.V392.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V392.User.User
    , credentials : Evergreen.V392.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
