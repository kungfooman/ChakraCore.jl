Void = Nothing # 1.0 ripped Void for whatever reason

const ch = "C:\\repos\\ChakraCore\\Build\\VcBuild\\bin\\x64_release\\ch.dll"
const cc = "C:\\Julia\\bin\\ChakraCore.dll"

#start_ch() = ccall( (:start_ch, ch), Void, ())
#start_ch()

const JsErrorCode = Int32
const JsRuntimeAttributeNone = Int32(0)

Base.pointer(ref::Ref) = Base.unsafe_convert(Ptr{eltype(ref)}, ref)
# deref is pretty much ref.x, but converting to Ptr{} here aswell
deref(ref::Ref) = Ptr{Int64}( ref.x )

runtime = Ref(0)
context = Ref(0)
result = Ref(0)
jsref = Ref(0)

ccall( (:JsCreateRuntime, cc), JsErrorCode, (Int32, Ptr{Int64}, Ptr{Int64}), 0, C_NULL, runtime)
print("got runtime=$runtime\n")

ccall( (:JsCreateContext, cc), JsErrorCode, (Ptr{Int64}, Ptr{Int64}), deref(runtime), context)
print("got context $context\n")

errorCode = ccall( (:JsSetCurrentContext, cc), JsErrorCode, (Ptr{Int64},), deref(context))
print("errorCode = $errorCode\n")

# JsRunScript(
#     _In_z_ const wchar_t *script,
#     _In_ JsSourceContext sourceContext,
#     _In_z_ const wchar_t *sourceUrl,
#     _Out_ JsValueRef *result);
errorCode = ccall( (:JsRunScript, cc), JsErrorCode, (Cwstring, Ptr{Int64}, Cwstring, Ptr{Int64}), "(()=>{return \'Hello world!\';})()", deref(context), "", result)
print("errorCode = $errorCode\n")

#=
jsref = Ptr{Int64}(0)
JsCreateObject() = ccall( (:JsCreateObject, cc), Int32, (Ptr{Int64},), jsref)
IfJsrtErrorSetGo(ChakraRTInterface::JsCreateContext(runtime, &newContext));
ccall( (:JsGetCurrentContext, cc), Void, (Ptr{Int64},), jsref)
# IfJsErrorFailLog(ChakraRTInterface::JsCreateRuntime(jsrtAttributes, nullptr, runtime));
#  65539 = JsErrorNoCurrentContext
#  65538 = JsErrorNullArgument
# 196610 = JsErrorScriptCompile
=#