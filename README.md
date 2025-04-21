# 🧾 RegToXML GPP Converter (v1.3)

Convert Windows Registry `.reg` files to Group Policy Preferences-compatible XML files using PowerShell.

This script simplifies the process of deploying multiple registry settings via GPO. Instead of manually editing XML, you can export registry settings from a reference machine and convert them into GPP XML using this tool.

---

## 💡 What does it do?

This PowerShell script converts exported Windows Registry files (`.reg`) into XML format for use with **Group Policy Preferences**. It supports all common registry value types:

- `REG_SZ`
- `REG_EXPAND_SZ`
- `REG_MULTI_SZ`
- `REG_BINARY`
- `REG_DWORD`
- `REG_QWORD`

---

## ⚙️ Prerequisites

- PowerShell **version 3 or higher**
- A valid `.reg` file (e.g., exported from a reference machine)

---

## 📦 Parameters

| Parameter     | Required | Description                                                                 |
|---------------|----------|-----------------------------------------------------------------------------|
| `FilePath`    | ✅ Yes    | Full path to the `.reg` file                                                |
| `ActionType`  | ❌ No     | GPP action to apply: `Create`, `Delete`, `Update`, or `Replace` (default: `Update`) |

---

## 🚀 Usage Examples

```powershell
# Basic conversion (default action = Update)
Convert-RegToGppXml.ps1 -FilePath "C:\MyTestRegFile.reg"

# With spaces in path
Convert-RegToGppXml.ps1 -FilePath "C:\Sub Folder\MyTestRegFile.reg"

# Specify action type (e.g., Create)
Convert-RegToGppXml.ps1 -FilePath "C:\MyTestRegFile.reg" -ActionType Create

# Combine path with custom action
Convert-RegToGppXml.ps1 -FilePath "C:\Sub Folder\MyTestRegFile.reg" -ActionType Replace
```

---

## 📝 Notes

- Only .reg files with standard formatting are supported.
- Paths and values are preserved and translated to the correct GPP structure.
- The generated XML conforms to Microsoft's GPP schema.

---

## 🙋 Feedback & Contributions
If you find this project useful or have suggestions, feel free to:

- ⭐ Star the repository
- 🐛 Submit issues
- 🔧 Contribute improvements via pull request

---

## 🔗 Related Projects
Active Directory Delegation Wizard 
https://github.com/janweis/Active-Directory-Delegation-Powershell-Wizard


