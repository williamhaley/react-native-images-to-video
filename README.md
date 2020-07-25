# react-native-images-to-video

Convert a series of images to a video

**This is iOS only for the moment and in alpha**

## Installation

```sh
npm install react-native-images-to-video
```

## Usage

```js
import ImagesToVideo from "react-native-images-to-video";

const videoURL = await ImagesToVideo.render({
    width: 300,
    height: 400,
    absolutePaths: ['/path/to/image1.jpg', '/path/to/image2.jpg'],
});
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
