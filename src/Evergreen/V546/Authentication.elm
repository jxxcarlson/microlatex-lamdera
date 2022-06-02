module Evergreen.V546.Authentication exposing (..)

import Dict
import Evergreen.V546.Credentials
import Evergreen.V546.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V546.User.User
    , credentials : Evergreen.V546.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
