module Evergreen.V675.Authentication exposing (..)

import Dict
import Evergreen.V675.Credentials
import Evergreen.V675.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V675.User.User
    , credentials : Evergreen.V675.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
