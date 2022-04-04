module Evergreen.V236.Authentication exposing (..)

import Dict
import Evergreen.V236.Credentials
import Evergreen.V236.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V236.User.User
    , credentials : Evergreen.V236.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
