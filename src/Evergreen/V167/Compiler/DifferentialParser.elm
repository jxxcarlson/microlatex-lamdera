module Evergreen.V167.Compiler.DifferentialParser exposing (..)

import Evergreen.V167.Compiler.AbstractDifferentialParser
import Evergreen.V167.Compiler.Acc
import Evergreen.V167.Parser.Block
import Evergreen.V167.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V167.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V167.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V167.Parser.Block.ExpressionBlock) Evergreen.V167.Compiler.Acc.Accumulator
