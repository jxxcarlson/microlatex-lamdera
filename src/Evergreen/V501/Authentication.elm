module Evergreen.V501.Authentication exposing (..)

import Dict
import Evergreen.V501.Credentials
import Evergreen.V501.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V501.User.User
    , credentials : Evergreen.V501.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
