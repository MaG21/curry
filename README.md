[![Build Status](https://travis-ci.org/MaG21/curry.svg?branch=master)](https://travis-ci.org/MaG21/curry)


## Currency scraper for the Dominican Republic

This is a simple service that provides the current currency exchange rate for<br>
the Dominican Republic. To do so, we parse the web pages of all the major banks<br>
of the Dominican Republic, those pages are updated on a daily basis by every<br>
bank.

The method used by this application to calculate the mean of the data is the<br>
_Harmonic mean_.

This application is freely available as a service thanks to<br>
_Marcos Organizador de Negocios S.R.L_ here http://api.marcos.do<br>


or<br>

you may make a pull request as well, if you see something that needs to be fixed<br>
or better implemented.<br>

## Install

```shell
$ bundle install
```

Please note that, this service not longer needs `imagemagik`, `ogcr` or `ocrad`.

This application uses port 8080 by default, one may change the port passing it as<br>
the first parameter:

```shell
$ ruby curry.rb 1025
```

## Known bugs

There's a bug in older versions of Ruby that causes this application to hang for<br>
an indefinite period of time. Please use Ruby 2.2 +

# Available actions

## ``GET /requests``

Returns the total number of requests successefully served up to this moment.

sample response:

	1092 requests.

## ``GET /rnc/:rnc``

Returns information about the RNC specified by `:rnc`. [JSON serialized]<br>

sample response:

```json
{
  "rnc": "131098193",
  "name": "MARCOS ORGANIZADOR DE NEGOCIOS SRL",
  "comercial_name": "MARCOS ORGANIZADOR DE NEGOCIOS",
  "category": "",
  "payment_regimen": "NORMAL",
  "status": "ACTIVO"
}
```

## ``GET /ncf/:rnc/:ncf``

Returns true or false, depending if the RNC and the NCF specified by :rnc and<br>
``:ncf`` respectively belongs to the entity associated to ``:rnc``<br>

sample response:

```json
{
  "valid": true
}
```

## ``GET /rates``

Returns the exchange rate for euros and dollars from all major banks of the<br>
Dominican Republic. [JSON serialized]<br>

```json
{
  "bpd": {
    "euro": {
      "buying_rate": "48.15",
      "selling_rate": "51.90"
    },
    "dollar": {
      "buying_rate": "45.05",
      "selling_rate": "45.56"
    },
    "source": "https://www.popularenlinea.com/_api/web/lists/getbytitle('Rates')/items"
  },
  "blh": {
    "euro": {
      "buying_rate": "48.00",
      "selling_rate": "51.00"
    },
    "dollar": {
      "buying_rate": "45.20",
      "selling_rate": "45.56"
    },
    "source": "http://www.blh.com.do/Inicio.aspx"
  },
  
  ...
  
  "euro_mean": {
    "buying_rate": "48.12",
    "selling_rate": "51.68"
  },
  "dollar_mean": {
    "buying_rate": "45.16",
    "selling_rate": "45.56"
  }
}
```

## ``GET /central_bank_rates``

Returns the exchange rate for the dollar according to the Central Bank of the<br>
Dominican Republic. [JSON serialized]

sample response:

```json
{
  "dollar": {
    "buying_rate": "45.76",
    "selling_rate": "45.81"
  }
}
```

## License
MIT License<br>

Copyright(C) 2018 Manuel A. Güílamo

