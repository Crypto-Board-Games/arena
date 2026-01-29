using Newtonsoft.Json;

using System.Runtime.Serialization;
using System.Text.Json.Serialization;

namespace Arena.Models.Entities;

public class DeviceIdentity
{
    [DataMember, JsonProperty("device_id"), JsonPropertyName("device_id")]
    public string? DeviceId
    {
        get; set;
    }
}