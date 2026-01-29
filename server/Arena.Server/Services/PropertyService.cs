using Microsoft.AspNetCore.Authentication;

using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Reflection;

namespace Arena.Services;

public class PropertyService
{
    public void SetValuesOfColumn<T>(T tuple, T param) where T : class
    {
        foreach (var property in tuple.GetType().GetProperties(BindingFlags.Instance | BindingFlags.Public))
        {
            if (property.CustomAttributes.Any(o => Array.Exists(types, type => type == o.AttributeType)))
            {
                continue;
            }
            var obj = param.GetType().GetProperty(property.Name)?.GetValue(param);

            string? value = obj?.ToString(), existingValue = property.GetValue(tuple)?.ToString();

            if (string.IsNullOrEmpty(value) || value.Equals(existingValue))
            {
                continue;
            }
            property.SetValue(tuple, obj);
        }
    }

    public IEnumerable<AuthenticationToken> GetEnumerator<T>(T property) where T : class
    {
        if (property != null)
        {
            foreach (var pi in property.GetType().GetProperties(BindingFlags.Instance | BindingFlags.Public))
            {
                if (pi.PropertyType == typeof(bool))
                {
                    continue;
                }
                if (pi.PropertyType != typeof(string) && pi.PropertyType.IsClass)
                {
                    var ctor = pi.GetValue(property);

                    if (ctor != null)
                    {
                        foreach (var token in GetEnumerator(ctor))
                        {
                            yield return token;
                        }
                    }
                    continue;
                }
                yield return new AuthenticationToken
                {
                    Name = pi.Name,
                    Value = Convert.ToString(pi.GetValue(property)) ?? string.Empty
                };
            }
        }
    }

    readonly Type[] types =
    [
        typeof(KeyAttribute),
        typeof(NotMappedAttribute)
    ];
}