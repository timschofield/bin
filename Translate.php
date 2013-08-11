#!/usr/bin/php5
<?php

function curl($url, $params = array(), $is_coockie_set = false) {

	if (!$is_coockie_set) {
		/* STEP 1. let’s create a cookie file */
		$ckfile = tempnam("/tmp", "CURLCOOKIE");

		/* STEP 2. visit the homepage to set the cookie properly */
		$ch = curl_init($url);
		curl_setopt($ch, CURLOPT_COOKIEJAR, $ckfile);
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
		$output = curl_exec($ch);
	}

	$str = '';
	$str_arr = array();
	foreach ($params as $key => $value) {
		$str_arr[] = urlencode($key) . "=" . urlencode($value);
	}
	if (!empty($str_arr))
		$str = '?' . implode('&', $str_arr);

	/* STEP 3. visit cookiepage.php */

	$Url = $url . $str;

	$ch = curl_init($Url);
	curl_setopt($ch, CURLOPT_COOKIEFILE, $ckfile);
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

	$output = curl_exec($ch);
	return $output;
}

function Translate($word, $from, $to) {
	$word = urlencode($word);
	// english to hindi
	$url = 'http://translate.google.com/translate_a/t?client=t&text=' . $word . '&hl=' . $from . '&sl=' . $from . '&tl=' . $to . '&ie=UTF-8&oe=UTF-8&multires=1&otf=1&ssel=3&tsel=3&sc=1';

	$name_en = curl($url);
	$name_en = str_replace(chr(92) . '" ', "'", $name_en);
	$name_en = str_replace(' ' . chr(92) . '"', "'", $name_en);
	$name_en = explode('"', $name_en);
	return $name_en[1];
}

exec ('xgettext --no-wrap --from-code=utf-8 --language=PHP -o locale/en_GB.utf8/LC_MESSAGES/messages.pot *php includes/*.php includes/*.inc reportwriter/*.php reportwriter/*.inc reportwriter/forms/*.html reportwriter/admin/*.php reportwriter/admin/*.inc reportwriter/admin/forms/*.html api/*.php install/*.php sql/updates/*.php');

$LocaleDirectories = scandir('locale/');

foreach ($LocaleDirectories as $Locale) {
	if ($Locale != '.' and $Locale != '..' and mb_substr($Locale, 0, 2) != 'en') {
		echo $Locale."\n";
		$ToLanguage = mb_substr($Locale, 0, 2);

		exec ('msgmerge -U --backup=off --no-wrap locale/' . $Locale . '/LC_MESSAGES/messages.po locale/en_GB.utf8/LC_MESSAGES/messages.pot');

		$FileReadHandle = fopen('locale/' . $Locale . '/LC_MESSAGES/messages.po', 'r');
		$FileWriteHandle = fopen('locale/' . $Locale . '/LC_MESSAGES/temp.po', 'w');

		while (($buffer = fgets($FileReadHandle, 4096)) !== false) {
			if (substr($buffer, 0, 5) == 'msgid') {
				if ($buffer != 'msgid ""' . "\n") {
					$StringToTranslate = mb_substr($buffer, 7, mb_strlen($buffer)-9);
					$Next = fgets($FileReadHandle, 4096);
					$TranslatedString = mb_substr($Next, 8, mb_strlen($Next)-10);
					if (mb_strlen($TranslatedString) == 0) {
						fputs($FileWriteHandle, $buffer);
						fputs($FileWriteHandle, 'msgstr "' . Translate($StringToTranslate, 'en', $ToLanguage) . '"' . "\n");
					} else {
						fputs($FileWriteHandle, $buffer);
						fputs($FileWriteHandle, $Next);
					}
				} else {
					fputs($FileWriteHandle, $buffer);
				}
			} else {
				fputs($FileWriteHandle, $buffer);
			}
		}
		fclose($FileReadHandle);
		fclose($FileWriteHandle);

		unlink('locale/' . $Locale . '/LC_MESSAGES/messages.po');
		rename('locale/' . $Locale . '/LC_MESSAGES/temp.po', 'locale/' . $Locale . '/LC_MESSAGES/messages.po');
		if ($Locale != 'en_GB.utf8') {
			exec('msgfmt -o locale/' . $Locale . '/LC_MESSAGES/messages.mo locale/' . $Locale . '/LC_MESSAGES/messages.po');
		}
	}
}

exec('git add locale/');
exec('git commit -m "Update translations to the latest strings"');
exec('git push');

?>