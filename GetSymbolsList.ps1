<#
.Synopsis
   Get Binance symbols list
.DESCRIPTION
   Get Binance symbols list for spot or futur (CM = COIN-M Futures, UM = USD-M Futures)
.EXAMPLE
   Get-SymbolsList -ContractType 'spot'
.EXAMPLE
   Get-SymbolsList -ContractType 'futures' -FuturesType 'cm'
.EXAMPLE
   Get-SymbolsList -ContractType 'futures' -FuturesType 'um'
#>
function Get-SymbolsList {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        
        [ValidateSet('spot', 'futures')]
        [string]
        $ContractType='spot',

        # Futures type (CM = COIN-M Futures, UM = USD-M Futures)
        [ValidateSet('cm', 'um')]
        [string]
        $FuturesType='um'
    )

    $symbolsFolder = "symbols-list"
    if (-not (Test-Path $symbolsFolder)) {
        $null = New-Item -ItemType Directory -Path $symbolsFolder
    }

    if ($ContractType -eq 'futures') {
        switch ($FuturesType) {
            cm { 
                    $baseUrl = 'https://dapi.binance.com/dapi/v1/exchangeInfo'
                    $symbolsFolder = Join-Path -Path $symbolsFolder -ChildPath "futur-cm.json"
            }
            um { 
                    $baseUrl = 'https://fapi.binance.com/fapi/v1/exchangeInfo'
                    $symbolsFolder = Join-Path -Path $symbolsFolder -ChildPath "futur-um.json"
            }
            Default {
                Write-Host "FuturesType must be set to 'cm' or 'um'"
            }
        }
    }
    # for spot    
    else {
        $baseUrl = 'https://api.binance.com/api/v3/exchangeInfo'
        $symbolsFolder = Join-Path -Path $symbolsFolder -ChildPath "spot.json"
    }

    try {
        $WebRequestResult = Invoke-WebRequest -Uri $baseUrl
        $jsonReponse = $WebRequestResult.Content | ConvertFrom-Json
    }
    #catch any webrequest error
    catch {
        $errorMessage = $_.Exception.Message
        $response = $_.Exception.Response
        if ($response -and $response.StatusCode -eq 404) {
            Write-Host "Warning : $($response.ResponseUri) $($response.StatusCode)." -ForegroundColor Yellow
        }
        else {
            Write-Host "Warning : $errorMessage" -ForegroundColor Yellow
            Write-Host "Warning : uri = $($params.Uri)" -ForegroundColor Yellow
        }
    }

    Write-Host "Getting all symbols for contract type $ContractType"
    @($jsonReponse).symbols.symbol | Out-File $symbolsFolder 
    Write-Verbose "Symbols saved in $symbolsFolder"
    
}

# Examples

#Get-SymbolsList -ContractType 'spot'
#Get-SymbolsList -ContractType 'futures' -FuturesType 'cm'
Get-SymbolsList -ContractType 'futures' -FuturesType 'um'