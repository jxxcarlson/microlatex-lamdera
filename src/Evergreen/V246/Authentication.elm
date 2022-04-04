module Evergreen.V246.Authentication exposing (..)

import Dict
import Evergreen.V246.Credentials
import Evergreen.V246.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V246.User.User
    , credentials : Evergreen.V246.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
