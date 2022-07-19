module Evergreen.V712.Authentication exposing (..)

import Dict
import Evergreen.V712.Credentials
import Evergreen.V712.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V712.User.User
    , credentials : Evergreen.V712.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
