module Evergreen.V428.Authentication exposing (..)

import Dict
import Evergreen.V428.Credentials
import Evergreen.V428.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V428.User.User
    , credentials : Evergreen.V428.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
