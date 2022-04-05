module Evergreen.V259.Authentication exposing (..)

import Dict
import Evergreen.V259.Credentials
import Evergreen.V259.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V259.User.User
    , credentials : Evergreen.V259.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
