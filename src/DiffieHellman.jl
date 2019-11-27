module DiffieHellman

using Random
using CryptoGroups

const _default_rng = Ref{RandomDevice}()
function __init__()
    _default_rng[] = RandomDevice()
end

default_rng() = _default_rng[]

function rngint(rng::AbstractRNG, len::Integer)
    max_n = ( BigInt(1) << len ) - 1
    if len > 2
        min_n = BigInt(1) << (len - 1)
        return rand(rng, min_n:max_n)
    end
    return rand(rng, 1:max_n)
end

function diffie(s,serialize::Function,deserialize::Function,sign::Function,verify::Function,G::AbstractGroup,rng::AbstractRNG)
    serialize(s,G)
    
    B,Bsign = deserialize(s)

    if verify(B,Bsign)

        t = security(G)
        a = rngint(rng,t)
        A = binary(G^a)

        serialize(s,(A,sign(A)))
        
        Bb = typeof(G)(B,G)
        key = value(Bb^a)
        return key
    else
        return Error("Key exchange failed.")
    end
end

diffie(io,serialize::Function,deserialize::Function,sign::Function,verify::Function,G::AbstractGroup) = diffie(io,serialize,deserialize,sign,verify,G,default_rng())

"""
This one returns a secret connection between two fixed parties. The signature function sign returns signature and the group with respect to which the signature was signed.
"""
function hellman(s,serialize::Function,deserialize::Function,sign::Function,verify::Function,rng::AbstractRNG)
    G = deserialize(s)

    t = security(G)
    b = rngint(rng,t) 
    
    B = binary(G^b)
    serialize(s,(B,sign(B)))
    
    A,Asign = deserialize(s)

    if verify(A,Asign)
        Aa = typeof(G)(A,G)
        key = value(Aa^b)
        return key
    else
        return Error("Key exchange failed.")
    end
end

hellman(io,serialize::Function,deserialize::Function,sign::Function,verify::Function) = hellman(io,serialize,deserialize,sign,verify,default_rng())

export diffie, hellman

end # module
