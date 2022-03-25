module Evergreen.V157.Compiler.DifferentialParser exposing (..)

import Evergreen.V157.Compiler.AbstractDifferentialParser
import Evergreen.V157.Compiler.Acc
import Evergreen.V157.Parser.Block
import Evergreen.V157.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V157.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V157.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V157.Parser.Block.ExpressionBlock) Evergreen.V157.Compiler.Acc.Accumulator
