module Evergreen.V195.Authentication exposing (..)

import Dict
import Evergreen.V195.Credentials
import Evergreen.V195.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V195.User.User
    , credentials : Evergreen.V195.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
