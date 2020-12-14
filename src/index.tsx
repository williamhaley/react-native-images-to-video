import { NativeModules } from 'react-native';
import { Decimal } from 'decimal.js';

interface ImagesToVideoOptions {
  fileName: string;
  screenTimePerImage: number;
  width: number;
  height: number;
  absolutePaths: Array<string>;
}

type ImagesToVideoType = {
  render(options: ImagesToVideoOptions): Promise<string>;
};

const { ImagesToVideo } = NativeModules;

const precision = 1000;

const ImagesToVideoHelper = {
  render(options: ImagesToVideoOptions): Promise<string> {
    const screenTimeDecimal = new Decimal(options.screenTimePerImage);

    const [timeValue, timeScale] = screenTimeDecimal.toFraction(precision);

    return ImagesToVideo.render({
      ...options,
      timeValue: timeValue.toNumber(),
      timeScale: timeScale.toNumber(),
    });
  },
};

export default ImagesToVideoHelper as ImagesToVideoType;
