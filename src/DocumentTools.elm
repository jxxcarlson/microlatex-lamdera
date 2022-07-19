module DocumentTools exposing (sort)

import Document exposing (Document)
import Effect.Time
import Types


sort : Types.SortMode -> List Document -> List Document
sort sortMode documents =
    let
        sort_ =
            case sortMode of
                Types.SortAlphabetically ->
                    List.sortBy (\doc -> doc.title)

                Types.SortByMostRecent ->
                    List.sortWith (\a b -> compare (Effect.Time.posixToMillis b.modified) (Effect.Time.posixToMillis a.modified))
    in
    sort_ documents
