module Evergreen.V400.Authentication exposing (..)

import Dict
import Evergreen.V400.Credentials
import Evergreen.V400.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V400.User.User
    , credentials : Evergreen.V400.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
