module Evergreen.V348.Authentication exposing (..)

import Dict
import Evergreen.V348.Credentials
import Evergreen.V348.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V348.User.User
    , credentials : Evergreen.V348.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
